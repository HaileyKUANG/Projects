/* ================================================================== */ 
## Tasks
## Summarize the unknown tables 
## Clarify questions

## Note
## The 2021 Spring experiment began on Jan 11, 2021, and ended on June 4, 2021
## (The first batch of participants enrolled in Nov.2020, however, the problem of having incorrect type of recommendation was fixed on Jan 11, 2021)
## N = 55 (teachers) is the final sample sizeresults_2021_cyu
/* ================================================================== */ 

/* ================================================================== */
/*  Query 0 */
/* ================================================================== */ 
SET @START_DATE:= '2021-01-10';
SET @END_DATE:= '2021-06-04';

/* ================================================================== */
/*  Query Drop Table */
/* ================================================================== */ 
DROP TABLE IF EXISTS vll.results_before_covid_cyu;
DROP TABLE IF EXISTS vll.results_2021_cyu;

/* ================================================================== */
/*  Query 1 */
/* ================================================================== */ 
## Create a table named "vll.results_2021_cyu"
## There are 26 variables/attributes in this table

CREATE TABLE vll.results_2021_cyu (
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
## Insert values to the following 9 variables/attributes in the table "vll.results_2021_cyu":
## 1. useraccount_id 
## 2. assessment_id 
## 3. topic_id --> video_id
## 4. test_type 
## 5. is_finished 
## 6. question_id 
## 7. user_given_answer_id 
## 8. user_given_answer_text 
## 9. result 

## 404,268 records has been inserted

INSERT INTO vll.results_2021_cyu
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
## Insert values to the following three variables/attributes in the table "vll.results_2021_cyu": 
## section_id
## display_name_section 
## display_name_topic

UPDATE
	vll.results_2021_cyu Y5table
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
## Insert values to the following variable/attribute: 
## time_attempted
## in the table "vll.results_2021_cyu"

UPDATE
	vll.results_2021_cyu Y5table
INNER JOIN TestYourselfAssessmentQuestions tyaq
	ON tyaq.question_id = Y5table.question_id
		AND tyaq.assessment_id = Y5table.assessment_id
SET
	Y5table.time_attempted = tyaq.ts_created;




/* ================================================================== */
/*  Query 5*/
/* ================================================================== */ 

## Insert values to the following variable/attribute in the table "vll.results_2021_cyu": 
## time_finished

## Meanwhile, only keep the finished sat
## 386,265 finished sat questions

UPDATE vll.results_2021_cyu Y5table
INNER JOIN TestYourselfAssessments tya
	ON tya.id = Y5table.assessment_id
SET
	Y5table.time_finished = tya.ts_modified
WHERE
	Y5table.is_finished = 1;


/* ================================================================== */
/*  Query 6-1*/
/* ================================================================== */ 
## Stamping the first attempt
## Added a new column named 'is_first_attempt' after 'time_finished'

ALTER TABLE vll.results_2021_cyu 
ADD COLUMN is_first_attempt tinyint(1) NULL 
COMMENT '' 
AFTER time_finished;



/* ================================================================== */
/*  Query 6-2*/
/* ================================================================== */ 
## Initial the following variable/attribute: 
## is_first_attempt
## in the table "vll.results_2021_cyu"

UPDATE vll.results_2021_cyu
SET is_first_attempt = 0;



/* ================================================================== */
/*  Query 6-3*/
/* ================================================================== */ 
## Insert values to the following variable/attribute in the table "vll.results_2021_cyu": 
## is_first_attempt


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
INNER JOIN vll.results_2021_cyu Y5table
	ON Y5table.assessment_id = tya.id
SET
	Y5table.is_first_attempt = 1;




/* ================================================================== */
/* Evaluate the table "is_first_attempt"*/
/* ================================================================== */ 
## At question level
## 246,036 first attempt
## 158,232 non-first attempt

SELECT count(is_first_attempt) 
FROM vll.results_2021_cyu
GROUP BY is_first_attempt;

## At assessment level
## 82,012 first attempt
## 52,744 non-first attempt

SELECT count(needed.is_first_attempt) 
FROM 	(SELECT useraccount_id, section_id, topic_id, test_type, assessment_id, is_first_attempt
		FROM vll.results_2021_cyu
        GROUP BY assessment_id) needed
GROUP BY needed.is_first_attempt;




/* ================================================================== */
/*  Specific Problem between is_finished and posttest*/
/* ================================================================== */ 
## Table TestYourselfAssessments 
## 11627 data entries
## 5 different question

SELECT * 
FROM TestYourselfAssessments TYS
WHERE TYS.useraccount_id IN (SELECT distinct useraccount_id from UserClusters)
AND TYS.is_finished = 1
AND TYS.test_type = 'pretest';

## ? 0
## None of the posttest was finished
## ! did not record is_finish
## begin as posttest
## after as regular tys
SELECT * 
FROM TestYourselfAssessments TYS
WHERE TYS.useraccount_id IN (SELECT distinct useraccount_id from UserClusters)
AND TYS.is_finished = 1
AND TYS.test_type = 'posttest';

SELECT * 
FROM TestYourselfAssessments TYS
WHERE TYS.is_finished = 1
AND TYS.test_type = 'posttest';

## Table vll_estimates  
SELECT * 
FROM vll_estimates 
WHERE vll_estimates.type = 'pretest' OR vll_estimates.type  = 'posttest'
AND ts_created between @START_DATE and @END_DATE;

## 13,810 posttest 
SELECT * 
FROM vll_estimates 
WHERE vll_estimates.type  = 'posttest'
AND ts_created between @START_DATE and @END_DATE;

/* ================================================================== */
/*  Query 7*/
/* ================================================================== */ 
## Insert values to the following variable/attribute in the table "vll.results_2021_cyu": 
## ability from estimates
UPDATE
	vll.results_2021_cyu Y5table
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
## Insert values to the following variable/attribute in the table "vll.results_2021_cyu": 
## setting engagement

UPDATE
	vll.results_2021_cyu Y5table
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
## Insert values to the following 5 variable/attribute in the table "vll.results_2021_cyu": 
## recommended_id 
## recommended_code
## recommended_tutor 
## recommended_location 
## followed 
UPDATE
	vll.results_2021_cyu Y5table
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
## Update values to the following 5 variable/attribute in the table "vll.results_2021_cyu": 
## recommended_id 
## recommended_code
## recommended_tutor 
## recommended_location 
## followed 
UPDATE
	vll.results_2021_cyu Y5table
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
-- Setting first attempt flag
UPDATE
	vll.results_2021_cyu 
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
## Insert values to the following 5 variable/attribute in the table "vll.results_2021_cyu": 
## has_watched_solution_video
## A table is missing
## ? vll_results_before_covid_cyu_prepared

UPDATE
	vll.results_2021_cyu Y5table
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
-- get results from the source, not grading script
UPDATE 
	vll.results_2021_cyu Y5table
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
## what are the types of this year?
-- CODES 2 and 4
UPDATE
	vll.results_2021_cyu Y5table
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
## ? vll_results_before_covid_cyu_prepared
-- ABILITY FROM previous CALCULATION

UPDATE
	vll.results_2021_cyu Y5table
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


-- Note: some questions were changed, so the answers were changed as well - i.e. re-graded.
-- question id 7943 was changed, so previous answer ["22(x+12)","660"] was considered wrong, but now is correct.
-- The previous correct was ["22(w+12)","660"]
-- This affects the recommendations.


/* ================================================================== */
/*  Query 33*/
/* ================================================================== */ 

SELECT
	rvt.*, 
    Y5table.recommended_code
FROM RecomendationVideosTracking rvt
INNER JOIN vll.results_2021_cyu Y5table
	ON Y5table.assessment_id = rvt.assessment_id
WHERE
	rvt.code <> Y5table.recommended_code
	AND rvt.code IS NOT NULL
	AND Y5table.recommended_code IS NOT NULL;




/* ================================================================== */
/*  Query 34*/
/* ================================================================== */ 
## ? vll_results_before_covid_cyu_original 

UPDATE
	vll.results_2021_cyu Y5table
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
## ? vll_results_before_covid_cyu_original 

UPDATE
	vll.results_2021_cyu Y5table
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
from vll.results_2021_cyu;


/* ================================================================== */
/*  Query 37*/
/* ================================================================== */ 
##? experiment_videos

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
		vll.results_2021_cyu Y5table
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
        

###############################################################################################
###############################################################################################
CREATE UNIQUE INDEX vll_tutor_recommendations_assessment_id_video_id_idx 
ON algebranation_production.vll_tutor_recommendations (assessment_id,video_id) 
USING BTREE;

CREATE INDEX vll_tutor_recommendations_useraccount_id_idx 
ON algebranation_production.vll_tutor_recommendations (useraccount_id) 
USING BTREE;

CREATE INDEX vll_tutor_recommendations_video_id_idx 
ON algebranation_production.vll_tutor_recommendations (video_id) 
USING BTREE;


/* ================================================================== */
/*  Query 38*/
/* ================================================================== */ 
## ? vll_tutor_recommendations

CREATE TABLE vll.tutor_video_watches
SELECT
	assessment_videos.assessment_id, 
    assessment_videos.section_id, 
    MIN(actions.id) AS 'first_action_after_recommendation'
FROM
	vll_tutor_recommendations assessment_videos
INNER JOIN TestYourselfAssessments tya
	ON tya.id = assessment_videos.assessment_id
LEFT JOIN (ActionTracking atr	
	INNER JOIN ActionTrackingVideo actions
		ON actions.action_tracking_id = atr.id
	INNER JOIN FolderTree ft
	    ON ft.id = actions.video_id)
    ON atr.session_log_id = tya.session_log_id
    	AND actions.ts_created > assessment_videos.time_finished
		AND (ft.parent_video_id = assessment_videos.recommended_id OR ft.id = assessment_videos.recommended_id)
GROUP BY
	assessment_videos.assessment_id, 
    assessment_videos.section_id;

###############################################################################################
###############################################################################################

CREATE UNIQUE INDEX `vll_tutor_video_watches_assessment_id_section_id_idx` ON `algebranation_production`.`vll_tutor_video_watches` (`assessment_id`,`section_id`) USING BTREE;
ALTER TABLE `algebranation_production`.`vll_tutor_video_watches` ADD COLUMN `previous_tutor_id` int NULL COMMENT '';
CREATE INDEX `vll_tutor_video_watches_previous_tutor_id_idx` ON `algebranation_production`.`vll_tutor_video_watches` (`previous_tutor_id`) USING BTREE;


/* ================================================================== */
/*  Query 39*/
/* ================================================================== */ 
## can't create this table
## ? vll_tutor_video_watches
## ? vll_tutor_recommendations
UPDATE
	vll.tutor_video_watches
INNER JOIN(
		SELECT
			recommendedations.assessment_id, 
            recommendedations.section_id, 
            MAX(actions.id) AS 'first_action_before_recommendation'
		FROM vll_tutor_video_watches watches
		INNER JOIN vll_tutor_recommendations recommendedations
			ON recommendedations.assessment_id = watches.assessment_id
		INNER JOIN TestYourselfAssessments tya
			ON tya.id = recommendedations.assessment_id
		INNER JOIN ActionTracking atr
			ON atr.session_log_id = tya.session_log_id
		INNER JOIN ActionTrackingVideo actions
			ON actions.action_tracking_id = atr.id
			AND actions.id < watches.first_action_after_recommendation
		INNER JOIN FolderTree ft
			ON ft.id = actions.video_id
			AND (ft.parent_video_id = recommendedations.recommended_id OR ft.id = recommendedations.recommended_id)
		GROUP BY
			recommendedations.assessment_id) previous_watch
	ON previous_watch.assessment_id = vll_tutor_video_watches.assessment_id
INNER JOIN ActionTrackingVideo av
	ON av.id = previous_watch.first_action_before_recommendation
INNER JOIN FolderTree ft
    ON ft.id = av.video_id
SET vll.tutor_video_watches.previous_tutor_id = ft.videotutor_id;


###############################################################################################
###############################################################################################
ALTER TABLE `algebranation_production`.`vll_results_before_covid_cyu` ADD COLUMN `changed_tutor` int NULL  AFTER `recommended_tutor`;


/* ================================================================== */
/*  Query 40*/
/* ================================================================== */ 
UPDATE
	vll.tutor_video_watches w
INNER JOIN vll.results_2021_cyu Y5table
	ON Y5table.assessment_id = w.assessment_id
SET
	Y5table.changed_tutor = 0
WHERE
	w.first_action_after_recommendation IS NULL
	AND
	Y5table.recommended_code IN (1,3);
    
    
/* ================================================================== */
/*  Query 41*/
/* ================================================================== */ 
##? 
UPDATE
	vll.results_2021_cyu 
INNER JOIN (
		SELECT
			Y5table.assessment_id, 
            IF(MOD(SUM(ft.videotutor_id),COUNT(*)) = 0, 
            IF(w.previous_tutor_id IS NULL, -- count only recommended and next
            IF(Y5table.recommended_tutor = FLOOR(SUM(ft.videotutor_id)/COUNT(*)), 1, 0),
            IF((FLOOR(SUM(ft.videotutor_id)/COUNT(*)) = Y5table.recommended_tutor)
            AND(Y5table.recommended_tutor <> w.previous_tutor_id), 1, 0)), 1 -- there was change
            ) AS 'changed'
		FROM vll.results_2021_cyu Y5table
        INNER JOIN vll_tutor_video_watches w
			ON r.assessment_id = w.assessment_id
		INNER JOIN vll_tutor_recommendations tr
			ON tr.assessment_id = r.assessment_id
			AND tr.section_id = w.section_id
		INNER JOIN TestYourselfAssessments tya
			ON tya.id = tr.assessment_id
		INNER JOIN ActionTracking atr
			ON atr.session_log_id = tya.session_log_id
		INNER JOIN ActionTrackingVideo actions
			ON actions.action_tracking_id = atr.id
			AND actions.id > w.first_action_after_recommendation
		INNER JOIN FolderTree ft
			ON ft.id = actions.video_id
    	AND (ft.parent_video_id = tr.recommended_id OR ft.id = tr.recommended_id)
		WHERE Y5table.recommended_code IN (1,3)
        AND w.first_action_after_recommendation IS NOT NULL
        GROUP BY Y5table.assessment_id) tutor_changes
	ON tutor_changes.assessment_id = vll.results_2021_cyu .assessment_id
SET vll.results_2021_cyu.changed_tutor = tutor_changes.changed;


/* ================================================================== */
/*  Query 42*/
/* ================================================================== */ 

UPDATE
	vll.results_2021_cyu Y5table
LEFT JOIN vll_tutor_video_watches w
	INNER JOIN vll_tutor_recommendations tr
	ON tr.assessment_id = w.assessment_id
ON tr.assessment_id = r.assessment_id
SET Y5table.changed_tutor = IF(
		w.previous_tutor_id IS NULL,
		1,
		IF( Y5table.recommended_tutor = w.previous_tutor_id,
			0,
			1))
WHERE
	Y5table.recommended_code IN (1,3)
	AND
	Y5table.changed_tutor IS NULL;

###############################################################################################
###############################################################################################
ALTER TABLE `algebranation_production`.`vll_results_before_covid_cyu` ADD COLUMN `review_incorrect_question` int NULL;



/* ================================================================== */
/*  Query 43*/
/* ================================================================== */ 
## Error Code: 1054. 
## Unknown column 'vll.results_2021_cyu.review_incorrect_question' in 'field list'


UPDATE
	vll.results_2021_cyu Y5table
INNER JOIN (
		SELECT
			assessments.assessment_id
		FROM(
			SELECT
				(@row_number:=@row_number + 1) AS rid, 
                IF(@uid <> results.useraccount_id, NULL, @timestamp) AS 'next_timestamp', 
                @timestamp := results.time_finished AS 'current_timestamp', 
                results.assessment_id, 
                results.time_finished,
                @uid := results.useraccount_id AS 'useraccount_id', 
                tya.session_log_id
			FROM (
				SELECT 	useraccount_id, 
						assessment_id, 
						time_finished 
				FROM 	vll.results_2021_cyu 
				GROUP BY assessment_id) results
			INNER JOIN TestYourselfAssessments tya
				ON tya.id = results.assessment_id
				AND tya.is_finished = 1
			CROSS JOIN (SELECT @row_number:=0, @uid:=0, @timestamp:=0) AS rowid
			WHERE results.time_finished IS NOT NULL 
			ORDER BY 	results.useraccount_id, 
						results.time_finished DESC) assessments
INNER JOIN ActionTracking atr
	ON atr.session_log_id = assessments.session_log_id
		AND atr.action_name = 'tys_review_incorrect_question'
-- 		AND atr.action_name IN ('tys_review_correct_question','tys_review_incorrect_question')
		AND UNIX_TIMESTAMP(atr.ts_created) BETWEEN (UNIX_TIMESTAMP(assessments.current_timestamp)) 
        AND COALESCE(UNIX_TIMESTAMP(assessments.next_timestamp), UNIX_TIMESTAMP(atr.ts_created)+180)) reviews
	ON reviews.assessment_id = Y5table.assessment_id
SET vll.results_2021_cyu.review_incorrect_question = 1;



/* ================================================================== */
/*  Query 44*/
/* ================================================================== */ 
UPDATE
	vll.results_2021_cyu 
SET recommended_code = NULL
WHERE
	is_finished = 0
	AND
	recommended_code IS NOT NULL;


/* ================================================================== */
/*  Query 45*/
/* ================================================================== */ 

-- set fractions
-- calculating by calendar 

UPDATE
	vll.results_2021_cyu 
INNER JOIN
(
	SELECT
		assessment_id, 
        GROUP_CONCAT(r.time_attempted), 
        MAX(r.time_attempted), 
        GROUP_CONCAT(log.fraction), 
        SUM(log.fraction)/COUNT(*) AS 'average', 
        MIN(log.fraction) AS 'fraction'
	FROM vll.results_2021_cyu Y5table
	INNER JOIN vll_fraction_log log
		ON log.useraccount_id = Y5table.useraccount_id
			AND log.ts_created BETWEEN DATE_ADD(r.time_attempted, INTERVAL -1 HOUR) AND DATE_ADD(r.time_attempted, INTERVAL 1 HOUR)
	GROUP BY
		Y5table.assessment_id
	HAVING
		average = fraction) fractions
	ON fractions.assessment_id = vll.results_2021_cyu.assessment_id
SET
	vll.results_2021_cyu .fraction = fractions.fraction;



/* ================================================================== */
/*  Query 46*/
/* ================================================================== */ 
## ? vll_results_before_covid_cyu_prepared
## ? vll_results_before_covid_cyu_raw

UPDATE
	vll_results_before_covid_cyu_prepared r
INNER JOIN vll_results_before_covid_cyu_raw raw
	ON r.assessment_id = raw.assessment_id
	AND r.question_id = raw.question_id
SET
	r.engagement = NULL, 
    r.fraction = NULL
WHERE
	r.recommended_code NOT IN (0,1,3)
    AND
    raw.engagement IS NULL;



/* ================================================================== */
/*  Query 47*/
/* ================================================================== */ 
## ? vll_results_before_covid_cyu_raw
SELECT
	Y5table.useraccount_id, 
    Y5table.assessment_id, 
    Y5table.section_id, 
    Y5table.topic_id, 
    Y5table.time_attempted, 
    Y5table.is_finished AS 'finished', 
    Y5table.ability AS 'ability', 
    raw.ability AS 'raw_ability', 
    Y5table.engagement AS 'engagement', 
    raw.engagement AS 'raw_engagement', 
    Y5table.fraction AS 'fraction', 
    raw.fraction AS 'raw_fraction', 
    Y5table.recommended_code AS 'code', 
    raw.recommended_code AS 'raw_code', 
    Y5table.recommended_tutor, 
    r.followed

FROM vll.results_2021_cyu Y5table
INNER JOIN vll_results_before_covid_cyu_raw raw
	ON Y5table.assessment_id = raw.assessment_id
	AND Y5table.question_id = raw.question_id
LEFT JOIN all_item_pars pars
    ON pars.question_id = Y5table.question_id
WHERE
	Y5table.recommended_code NOT IN (0,1,3)
	AND
	Y5table.is_finished = 1
    AND
-- 	r.ability IS NULL
--     AND
-- 	pars.id IS NULL
	(Y5table.ability = raw.ability);

/* ================================================================== */
/*  Query 48*/
/* ================================================================== */ 

SELECT
	useraccount_id, 
    assessment_id, 
    section_id, 
    topic_id, 
    time_attempted, 
    time_finished, 
    SUM(IF(
		is_finished = 1
		, 1
		, 
		IF (
			user_given_answer_id IS NOT NULL OR user_given_answer_text IS NOT NULL
			, 1
			, 0
		)
	)) AS 'answered_questions', 
    COALESCE(review_incorrect_question, 0) AS 'review_incorrect_question', 
    SUM(result) AS 'correct', 
    ability, 
    engagement, 
    fraction, 
    recommended_code, 
    recommended_id AS 'recommended_video', 
    followed, 
    changed_tutor
FROM  vll.results_2021_cyu 
GROUP BY
	useraccount_id, 
    assessment_id
ORDER BY
	useraccount_id, 
    assessment_id;
