/* ================================================================== */ 
## Tasks
## Summarize the tables 


/* ================================================================== */
/*  Query 0 */
/* ================================================================== */ 
SET @START_DATE:= '2021-01-10';
SET @END_DATE:= '2021-06-04';

/* ================================================================== */
/*  Query Drop Table */
/* ================================================================== */ 
DROP TABLE IF EXISTS vx.t1;
DROP TABLE IF EXISTS vx.t2;

/* ================================================================== */
/*  Query 1 */
/* ================================================================== */ 
CREATE TABLE vx.t2 (
  useraccount_id int(11) NOT NULL,
  assessment_id int(11) unsigned NOT NULL DEFAULT '0',
  section_id int(11) DEFAULT NULL,
  topic_id int(11) unsigned NOT NULL,
  test_type varchar(17) CHARACTER SET utf8 DEFAULT NULL,
  is_finished tinyint(1) unsigned NOT NULL DEFAULT '0',
  question_id int(11) unsigned NOT NULL,
  user_given_answer_id int(11) unsigned DEFAULT NULL,
  user_given_answer_text text CHARACTER SET utf8,
  result varchar(9) CHARACTER SET utf8 NOT NULL DEFAULT '',
  
  display_name_section varchar(255) DEFAULT NULL,
  display_name_topic varchar(255) DEFAULT NULL,
  processed tinyint(1) DEFAULT NULL,
  has_watched_solution_video tinyint(1) DEFAULT NULL,
  time_attempted timestamp NULL DEFAULT NULL,
  time_finished timestamp NULL DEFAULT NULL,
  recorded tinyint(1) DEFAULT NULL,
  estimated varchar(255) DEFAULT NULL,
  engagement varchar(255) DEFAULT NULL,
  fraction varchar(255) DEFAULT NULL,
  ability varchar(255) DEFAULT NULL,
  recommended_id varchar(255) DEFAULT NULL,
  recommended_code varchar(255) DEFAULT NULL,
  recommended_tutor varchar(255) DEFAULT NULL,
  recommended_location varchar(255) DEFAULT NULL,
  followed varchar(255) DEFAULT NULL,
  UNIQUE KEY results_2021_cyu_assessment_id_question_id_idx (assessment_id, question_id) USING BTREE) 
  ENGINE = InnoDB;




/* ================================================================== */
/*  Query 2 */
/* ================================================================== */ 
INSERT INTO vx.t2
SELECT
	std.useraccount_id, 
    tya.id AS 'assessment_id', 
    NULL,	## section_id
    tysq.video_id AS 'topic_id', 
    IF(	ISNULL(estimates.type), tya.test_type, estimates.type) AS 'test_type', 
    tya.is_finished, 
    tyaq.question_id, 
    tyaq.user_given_answer_id, 
    tyaq.user_given_answer_text, 
    IF(ISNULL(tyaq.user_given_answer_id) AND ISNULL(tyaq.user_given_answer_text), 99,
		IF(ISNULL(tyaq.user_given_answer_text),
			IF(tyaq.user_given_answer_id = tyq.correct_answer_id, 'correct', 'incorrect'), 'undefined')) 'result', 
            
	NULL, 	## display_name_section
    NULL, 	## display_name_topic
    NULL, 	## processed
    NULL, 	## has_watched_solution_video
    NULL, 	## time_attempted
    NULL, 	## time_finished
    NULL, 	## recorded
    NULL, 	## estimated
    NULL, 	## engagement
    NULL, 	## fraction
    NULL, 	## ability
    NULL,	## recommended_id
    NULL, 	## recommended_code
    NULL, 	## recommended_tutor
    NULL,	## recommended_location
    NULL 	## followed
    
FROM UserClusters std
INNER JOIN TestYourselfAssessments tya
	ON std.useraccount_id = tya.useraccount_id
INNER JOIN TestYourselfAssessmentQuestions tyaq
	ON tya.id = tyaq.assessment_id
LEFT JOIN TestYourselfSatQuestions tysq
## should be left join this table
## without and with this table
	ON tyaq.question_id = tysq.question_id
	AND tya.section_folder_id = tysq.video_id
	AND tya.subject_id = tysq.subject_id
	AND tysq.subject_id = 1001 ## ? Should I use subject_id = 1001
LEFT JOIN TestYourselfQuestions tyq
	ON tysq.question_id = tyq.id
LEFT JOIN vll_estimates estimates
	ON estimates.assessment_id = tya.id
WHERE(DATE(CONVERT_TZ(tya.ts_created, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE
	OR DATE(CONVERT_TZ(tya.ts_modified, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE);




/* ================================================================== */
/*  Query 3*/
/* ================================================================== */ 
UPDATE
	vx.t2 Y5table
INNER JOIN FolderTree ft
	ON ft.id = Y5table.topic_id
LEFT JOIN FolderTree parent
	ON (parent.id = ft.parent_folder_id AND ft.parent_folder_id IS NOT NULL)
SET
	Y5table.display_name_topic = ft.display_name,
    Y5table.section_id = parent.testyourself_section_folder_id, 
    Y5table.display_name_section = parent.display_name;



/* ================================================================== */
/*  Query 4*/
/* ================================================================== */ 
UPDATE
	vx.t2 Y5table
INNER JOIN TestYourselfAssessmentQuestions tyaq
	ON tyaq.question_id = Y5table.question_id
		AND tyaq.assessment_id = Y5table.assessment_id
SET
	Y5table.time_attempted = tyaq.ts_created;




/* ================================================================== */
/*  Query 5*/
/* ================================================================== */ 
UPDATE vx.t2 Y5table
INNER JOIN TestYourselfAssessments tya
	ON tya.id = Y5table.assessment_id
SET
	Y5table.time_finished = tya.ts_modified
WHERE
	Y5table.is_finished = 1;


/* ================================================================== */
/*  Query 6-1*/
/* ================================================================== */ 
ALTER TABLE vx.t2 
ADD COLUMN is_first_attempt tinyint(1) NULL 
COMMENT '' 
AFTER time_finished;



/* ================================================================== */
/*  Query 6-2*/
/* ================================================================== */ 
UPDATE vx.t2
SET is_first_attempt = 0;



/* ================================================================== */
/*  Query 6-3*/
/* ================================================================== */ 
UPDATE 
(SELECT
		tya.useraccount_id, 
        MIN(tya.ts_modified) AS 'first_time', 
        tya.section_folder_id
	FROM UserClusters uc
	INNER JOIN TestYourselfAssessments tya
		ON uc.useraccount_id = tya.useraccount_id
			AND (tya.is_finished = 1)
			AND (tya.test_type = 'sat')
			AND DATE(CONVERT_TZ(tya.ts_modified, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE
	GROUP BY
		tya.useraccount_id, tya.section_folder_id) first_finished_attempts
INNER JOIN TestYourselfAssessments tya
	ON tya.useraccount_id = first_finished_attempts.useraccount_id
		AND tya.section_folder_id = first_finished_attempts.section_folder_id
		AND tya.ts_modified = first_finished_attempts.first_time
INNER JOIN vx.t2 Y5table
	ON Y5table.assessment_id = tya.id
SET
	Y5table.is_first_attempt = 1;




/* ================================================================== */
/* Evaluate the table "is_first_attempt"*/
/* ================================================================== */ 
SELECT count(is_first_attempt) 
FROM vx.t2
GROUP BY is_first_attempt;

SELECT count(needed.is_first_attempt) 
FROM 	(SELECT useraccount_id, section_id, topic_id, test_type, assessment_id, is_first_attempt
		FROM vx.t2
        GROUP BY assessment_id) needed
GROUP BY needed.is_first_attempt;




/* ================================================================== */
/*  Specific Problem */
/* ================================================================== */ 
SELECT * 
FROM TestYourselfAssessments TYS
WHERE TYS.useraccount_id IN (SELECT distinct useraccount_id from UserClusters)
AND TYS.is_finished = 1
AND TYS.test_type = 'pretest';

SELECT * 
FROM TestYourselfAssessments TYS
WHERE TYS.useraccount_id IN (SELECT distinct useraccount_id from UserClusters)
AND TYS.is_finished = 1
AND TYS.test_type = 'posttest';

SELECT * 
FROM TestYourselfAssessments TYS
WHERE TYS.is_finished = 1
AND TYS.test_type = 'posttest';

 
SELECT * 
FROM vll_estimates 
WHERE vll_estimates.type = 'pretest' OR vll_estimates.type  = 'posttest'
AND ts_created between @START_DATE and @END_DATE;

SELECT * 
FROM vll_estimates 
WHERE vll_estimates.type  = 'posttest'
AND ts_created between @START_DATE and @END_DATE;

/* ================================================================== */
/*  Query 7*/
/* ================================================================== */ 

UPDATE
	vx.t2 Y5table
INNER JOIN UserClusters clusters
	ON Y5table.useraccount_id = clusters.useraccount_id
INNER JOIN TestYourselfAssessments TYS
	ON TYS.id = Y5table.assessment_id
	AND TYS.subject_id = 1001
INNER JOIN vll_estimates estimates
	ON estimates.assessment_id = Y5table.assessment_id
SET
	Y5table.ability = estimates.ability;
-- WHERE
-- 	TYS.is_finished = 1




/* ================================================================== */
/*  Query 8*/
/* ================================================================== */ 
UPDATE
	vx.t2 Y5table
INNER JOIN vll_estimates estimates
	ON Y5table.assessment_id = estimates.assessment_id
INNER JOIN vll_predictions predictions
	ON estimates.useraccount_id = predictions.useraccount_id
		AND UNIX_TIMESTAMP(predictions.ts_created) BETWEEN (UNIX_TIMESTAMP(estimates.ts_created)-7) AND (UNIX_TIMESTAMP(estimates.ts_created) + 7)
SET
	Y5table.engagement = predictions.prediction
WHERE
	estimates.calculation_type = 'direct';



/* ================================================================== */
/*  Query 9 -1 */
/* ================================================================== */ 
UPDATE
	vx.t2 Y5table
INNER JOIN RecomendationVideosTracking rvt
	ON rvt.assessment_id = Y5table.assessment_id
SET
	Y5table.recommended_id = COALESCE(rvt.recommended_section, Y5table.recommended_id),
	Y5table.recommended_code = COALESCE(rvt.code, Y5table.recommended_code),
	Y5table.recommended_tutor = COALESCE(rvt.tutor_id, Y5table.recommended_tutor),
	Y5table.recommended_location = COALESCE(rvt.location, Y5table.recommended_location),
	Y5table.followed = COALESCE(rvt.followed, Y5table.followed);




/* ================================================================== */
/*  Query 9-2*/
/* ================================================================== */ 
UPDATE
	vx.t2 Y5table
INNER JOIN (
			SELECT
				rvt.tested_section, 
                rvt.recommended_section, 
                rvt.ts_modified, 
                rvt.code, 
                rvt.followed, 
                rvt.location, 
                rvt.tutor_id, 
                r.assessment_id, 
                r.time_finished, 
                SECOND(TIMEDIFF(r.time_finished, rvt.ts_modified))
			FROM RecomendationVideosTracking rvt 
			INNER JOIN TestYourselfAssessments tya
				ON tya.useraccount_id = rvt.useraccount_id
				AND tya.section_folder_id = rvt.tested_section
				AND tya.session_log_id = rvt.session_log_id
			INNER JOIN TestYourselfAssessmentQuestions tyaq
				ON tyaq.assessment_id = tya.id
			INNER JOIN vll.results_2021_cyu r
				ON r.assessment_id = tyaq.assessment_id
				AND r.question_id = tyaq.question_id
			WHERE
				rvt.assessment_id IS NULL
				AND SECOND(TIMEDIFF(r.time_finished, rvt.ts_modified)) < 45
			GROUP BY
				rvt.useraccount_id, rvt.tested_section
			HAVING COUNT(DISTINCT tya.id) = 1) missed
	ON missed.assessment_id = Y5table.assessment_id
SET
	Y5table.recommended_id = missed.recommended_section,
	Y5table.recommended_code = missed.code,
	Y5table.recommended_tutor = missed.tutor_id,
	Y5table.recommended_location = missed.location,
	Y5table.followed = missed.followed;



/* ================================================================== */
/*  Query 28*/
/* ================================================================== */ 
UPDATE
	vx.t2 
INNER JOIN (
	SELECT
	    Y5table.assessment_id, 
        Y5table.is_first_attempt, 
        COUNT(DISTINCT previous.id) AS 'previously_finished'
    FROM
        vll.results_2021_cyu Y5table
    LEFT JOIN TestYourselfAssessments previous
        ON previous.useraccount_id = Y5table.useraccount_id
		AND previous.test_type = 'sat'
		AND previous.section_folder_id = Y5table.topic_id
		AND previous.id <> Y5table.assessment_id
		AND previous.ts_modified < Y5table.time_finished
		AND previous.is_finished = 1
    WHERE
        Y5table.is_finished = 1
    GROUP BY
		Y5table.assessment_id) attempts
	ON attempts.assessment_id = vll.results_2021_cyu.assessment_id
SET vll.results_2021_cyu.is_first_attempt = IF(attempts.previously_finished, 0, 1);




/* ================================================================== */
/*  Query 29*/
/* ================================================================== */ 
UPDATE
	vx.t2 Y5table
INNER JOIN vll_results_before_covid_cyu_prepared original
	ON Y5table.assessment_id = original.assessment_id
	AND Y5table.question_id = original.question_id
SET
	Y5table.result = original.result, 
    Y5table.processed = 1, 
    Y5table.has_watched_solution_video = original.has_watched_solution_video;



/* ================================================================== */
/*  Query 30*/
/* ================================================================== */ 
UPDATE 
	vx.t2 Y5table
INNER JOIN TestYourselfAssessmentQuestions tyaq
	ON Y5table.assessment_id = tyaq.assessment_id
	AND Y5table.question_id = tyaq.question_id
INNER JOIN (
	SELECT
		tya.id AS 'assessment_id', 
        SUM(tyaq.user_gave_correct_answer) AS 'correct', 
        SUM(Y5table0.result) AS 'result'
	FROM 
		TestYourselfAssessments tya
	INNER JOIN TestYourselfAssessmentQuestions tyaq
		ON tyaq.assessment_id = tya.id
	INNER JOIN vll.results_2021_cyu Y5table0
		ON Y5table0.assessment_id = tyaq.assessment_id
		AND Y5table0.question_id = tyaq.question_id
	WHERE
		tya.is_finished = 1
	GROUP BY
		tya.id
	HAVING
		correct <> result) incorrect
	ON incorrect.assessment_id = Y5table.assessment_id
SET Y5table.result = tyaq.user_gave_correct_answer;




/* ================================================================== */
/*  Query 31*/
/* ================================================================== */ 

UPDATE
	vx.t2 Y5table
INNER JOIN (
	SELECT assessment_id, SUM(result) AS 'score' 
    FROM vll.results_2021_cyu  
    GROUP BY assessment_id 
    HAVING score > 1) scored
	ON Y5table.assessment_id = scored.assessment_id
SET
	Y5table.recommended_code = IF(scored.score = 2, 2, 4);


/* ================================================================== */
/*  Query 32*/
/* ================================================================== */ 
UPDATE
	vx.t2 Y5table
INNER JOIN vll_results_before_covid_cyu_prepared prepared
	ON Y5table.assessment_id = prepared.assessment_id
	AND Y5table.question_id = prepared.question_id
LEFT JOIN all_item_pars pars
    ON pars.question_id = Y5table.question_id
SET Y5table.ability = prepared.ability
WHERE
	Y5table.recommended_code NOT IN (2,4)
	AND pars.id IS NOT NULL
	AND prepared.ability IS NOT NULL;


/* ================================================================== */
/*  Query 33*/
/* ================================================================== */ 

SELECT
	rvt.*, 
    Y5table.recommended_code
FROM RecomendationVideosTracking rvt
INNER JOIN vx.t2 Y5table
	ON Y5table.assessment_id = rvt.assessment_id
WHERE
	rvt.code <> Y5table.recommended_code
	AND rvt.code IS NOT NULL
	AND Y5table.recommended_code IS NOT NULL;




/* ================================================================== */
/*  Query 34*/
/* ================================================================== */ 
UPDATE
	vx.t2 Y5table
INNER JOIN vll_results_before_covid_cyu_original original
	ON Y5table.assessment_id = original.assessment_id
	AND Y5table.question_id = original.question_id
SET
	Y5table.engagement = original.engagement
WHERE
	Y5table.is_first_attempt = 1
	AND 
	Y5table.engagement IS NULL
	AND 
	original.engagement IS NOT NULL
	AND
	original.recommended_code IN (0, 1, 3);



/* ================================================================== */
/*  Query 35*/
/* ================================================================== */ 
UPDATE
	vx.t2 Y5table
INNER JOIN vll_results_before_covid_cyu_original original
	ON Y5table.assessment_id = original.assessment_id
	AND Y5table.question_id = original.question_id
SET
	Y5table.fraction = original.fraction
WHERE
	Y5table.is_first_attempt = 1
	AND 
	Y5table.fraction IS NULL
	AND 
	original.fraction IS NOT NULL;


/* ================================================================== */
/*  Query 36*/
/* ================================================================== */ 
select * 
from vx.t2;


/* ================================================================== */
/*  Query 37*/
/* ================================================================== */ 
CREATE TABLE vll.tutor_recommendations
	SELECT
		Y5table.assessment_id, 
        Y5table.useraccount_id, 
        Y5table.recommended_tutor, 
        Y5table.recommended_id, 
        Y5table.time_finished, 
        sections.section_id, 
        videos.video_id
	FROM
		vx.t2 Y5table
	INNER JOIN TestYourselfAssessmentQuestions tyaq
		ON tyaq.assessment_id = Y5table.assessment_id
		AND tyaq.question_id = Y5table.question_id
	INNER JOIN experiment_videos sections
		ON sections.video_id = Y5table.recommended_id
	INNER JOIN experiment_videos videos
		ON sections.section_id = videos.section_id
	WHERE
		Y5table.recommended_code IN (1,3) 
	GROUP BY
		Y5table.assessment_id, 
        Y5table.recommended_id, 
        videos.video_id;