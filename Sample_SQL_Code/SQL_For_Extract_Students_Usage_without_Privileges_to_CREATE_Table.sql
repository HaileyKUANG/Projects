/* ================================================================== */ 
## Tasks
## Use the code to creat tables and get the data for LAK 

/* ================================================================== */ 

SET @START_DATE:= '2021-08-01';
SET @END_DATE:= '2021-12-31';

/* ================================================================== */
/*  Query 1 */
/* ================================================================== */ 
## Capture the info for "vll_results_2021_cyu" without creating a table

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
    IF(	ISNULL(tyaq.user_given_answer_id) AND ISNULL(tyaq.user_given_answer_text), 99,
		IF(ISNULL(tyaq.user_given_answer_text),
			IF(tyaq.user_given_answer_id = tyq.correct_answer_id, 'correct', 'incorrect'), 'undefined')) 'result'
            
FROM UserClusters std
INNER JOIN TestYourselfAssessments tya
	ON std.useraccount_id = tya.useraccount_id
	AND (tya.test_type = 'sat') ## CheckYourUnderstanding
INNER JOIN TestYourselfAssessmentQuestions tyaq
	ON tya.id = tyaq.assessment_id
INNER JOIN TestYourselfSatQuestions tysq
	ON tyaq.question_id = tysq.question_id
	AND tya.section_folder_id = tysq.video_id
	AND tya.subject_id = tysq.subject_id
	AND tysq.subject_id = 1001 ## Need to change to more specific constricts
INNER JOIN TestYourselfQuestions tyq
	ON tysq.question_id = tyq.id
LEFT JOIN vll_estimates estimates
	ON estimates.assessment_id = tya.id
		AND estimates.type = 'sat' ## CheckYourUnderstanding
WHERE(DATE(CONVERT_TZ(tya.ts_created, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE
	OR DATE(CONVERT_TZ(tya.ts_modified, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE);


/* ================================================================== */
/*  Query 2*/
/* ================================================================== */ 
## Join the result of Query 1 and "display_name_section" & "display_name_topic" without creating a table

SELECT 
	Y5table.useraccount_id,
    Y5table.assessment_id,
    parent.testyourself_section_folder_id AS 'section_id',
    Y5table.topic_id,
	Y5table.test_type,
	Y5table.is_finished,
    Y5table.question_id,
    Y5table.user_given_answer_id, 
	Y5table.user_given_answer_text, 
	Y5table.result,
	ft.display_name AS 'display_name_topic',
	parent.display_name AS 'display_name_section'

FROM 
	(SELECT
		std.useraccount_id, 
		tya.id AS 'assessment_id', 
		tysq.video_id AS 'topic_id', 
		IF(	ISNULL(estimates.type), tya.test_type, estimates.type) AS 'test_type', 
		tya.is_finished, 
		tyaq.question_id, 
		tyaq.user_given_answer_id, 
		tyaq.user_given_answer_text, 
		IF(	ISNULL(tyaq.user_given_answer_id) AND ISNULL(tyaq.user_given_answer_text), 99,
			IF(ISNULL(tyaq.user_given_answer_text),
				IF(tyaq.user_given_answer_id = tyq.correct_answer_id, 'correct', 'incorrect'), 'undefined')) 'result'
				
	FROM UserClusters std
	INNER JOIN TestYourselfAssessments tya
		ON std.useraccount_id = tya.useraccount_id
		AND (tya.test_type = 'sat') ## CheckYourUnderstanding
	INNER JOIN TestYourselfAssessmentQuestions tyaq
		ON tya.id = tyaq.assessment_id
	INNER JOIN TestYourselfSatQuestions tysq
		ON tyaq.question_id = tysq.question_id
		AND tya.section_folder_id = tysq.video_id
		AND tya.subject_id = tysq.subject_id
		AND tysq.subject_id = 1001 ## Need to change to more specific constricts
	INNER JOIN TestYourselfQuestions tyq
		ON tysq.question_id = tyq.id
	LEFT JOIN vll_estimates estimates
		ON estimates.assessment_id = tya.id
			AND estimates.type = 'sat' ## CheckYourUnderstanding
	WHERE(DATE(CONVERT_TZ(tya.ts_created, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE
		OR DATE(CONVERT_TZ(tya.ts_modified, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE)) Y5table
    
INNER JOIN FolderTree ft
	ON ft.id = Y5table.topic_id
LEFT JOIN FolderTree parent
	ON (parent.id = ft.parent_folder_id AND ft.parent_folder_id IS NOT NULL);


/* ================================================================== */
/*  Query 3*/
/* ================================================================== */ 
## Join the result of Query 2 and "time_attempted" without creating a table

SELECT 
	Y5table.useraccount_id,
    Y5table.assessment_id,
    parent.testyourself_section_folder_id AS 'section_id',
    Y5table.topic_id,
	Y5table.test_type,
	Y5table.is_finished,
    Y5table.question_id,
    Y5table.user_given_answer_id, 
	Y5table.user_given_answer_text, 
	Y5table.result,
	ft.display_name AS 'display_name_topic',
	parent.display_name AS 'display_name_section',
    Y5table.ts_created AS 'time_attempted'

FROM 
	(SELECT
		std.useraccount_id, 
		tya.id AS 'assessment_id', 
		tysq.video_id AS 'topic_id', 
		IF(	ISNULL(estimates.type), tya.test_type, estimates.type) AS 'test_type', 
		tya.is_finished, 
		tyaq.question_id, 
		tyaq.user_given_answer_id, 
		tyaq.user_given_answer_text, 
        tyaq.ts_created,
		IF(	ISNULL(tyaq.user_given_answer_id) AND ISNULL(tyaq.user_given_answer_text), 99,
			IF(ISNULL(tyaq.user_given_answer_text),
				IF(tyaq.user_given_answer_id = tyq.correct_answer_id, 'correct', 'incorrect'), 'undefined')) 'result'
				
	FROM UserClusters std
	INNER JOIN TestYourselfAssessments tya
		ON std.useraccount_id = tya.useraccount_id
		AND (tya.test_type = 'sat') ## CheckYourUnderstanding
	INNER JOIN TestYourselfAssessmentQuestions tyaq
		ON tya.id = tyaq.assessment_id
	INNER JOIN TestYourselfSatQuestions tysq
		ON tyaq.question_id = tysq.question_id
		AND tya.section_folder_id = tysq.video_id
		AND tya.subject_id = tysq.subject_id
		AND tysq.subject_id = 1001 ## Need to change to more specific constricts
	INNER JOIN TestYourselfQuestions tyq
		ON tysq.question_id = tyq.id
	LEFT JOIN vll_estimates estimates
		ON estimates.assessment_id = tya.id
			AND estimates.type = 'sat' ## CheckYourUnderstanding
	WHERE(DATE(CONVERT_TZ(tya.ts_created, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE
		OR DATE(CONVERT_TZ(tya.ts_modified, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE)) Y5table
    
INNER JOIN FolderTree ft
	ON ft.id = Y5table.topic_id
LEFT JOIN FolderTree parent
	ON (parent.id = ft.parent_folder_id AND ft.parent_folder_id IS NOT NULL);


/* ================================================================== */
/*  Query 4*/
/* ================================================================== */ 
## Join the result of Query 3 and "time_finished" without creating a table

SELECT 
	Y5table.useraccount_id,
    Y5table.assessment_id,
    parent.testyourself_section_folder_id AS 'section_id',
    Y5table.topic_id,
	Y5table.test_type,
	Y5table.is_finished,
    Y5table.question_id,
    Y5table.user_given_answer_id, 
	Y5table.user_given_answer_text, 
	Y5table.result,
	ft.display_name AS 'display_name_topic',
	parent.display_name AS 'display_name_section',
    Y5table.ts_created AS 'time_attempted',
    Y5table.ts_modified AS 'time_finished'

FROM 
	(SELECT
		std.useraccount_id, 
		tya.id AS 'assessment_id', 
		tysq.video_id AS 'topic_id', 
		IF(	ISNULL(estimates.type), tya.test_type, estimates.type) AS 'test_type', 
		tya.is_finished, 
		tyaq.question_id, 
		tyaq.user_given_answer_id, 
		tyaq.user_given_answer_text, 
        tyaq.ts_created,
        tya.ts_modified,
		IF(	ISNULL(tyaq.user_given_answer_id) AND ISNULL(tyaq.user_given_answer_text), 99,
			IF(ISNULL(tyaq.user_given_answer_text),
				IF(tyaq.user_given_answer_id = tyq.correct_answer_id, 'correct', 'incorrect'), 'undefined')) 'result'
				
	FROM UserClusters std
	INNER JOIN TestYourselfAssessments tya
		ON std.useraccount_id = tya.useraccount_id
		AND (tya.test_type = 'sat') ## CheckYourUnderstanding
	INNER JOIN TestYourselfAssessmentQuestions tyaq
		ON tya.id = tyaq.assessment_id
        AND tya.is_finished = 1
	INNER JOIN TestYourselfSatQuestions tysq
		ON tyaq.question_id = tysq.question_id
		AND tya.section_folder_id = tysq.video_id
		AND tya.subject_id = tysq.subject_id
		AND tysq.subject_id = 1001 ## Need to change to more specific constricts
	INNER JOIN TestYourselfQuestions tyq
		ON tysq.question_id = tyq.id
	LEFT JOIN vll_estimates estimates
		ON estimates.assessment_id = tya.id
			AND estimates.type = 'sat' ## CheckYourUnderstanding
	WHERE(DATE(CONVERT_TZ(tya.ts_created, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE
		OR DATE(CONVERT_TZ(tya.ts_modified, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE)) Y5table
    
INNER JOIN FolderTree ft
	ON ft.id = Y5table.topic_id
LEFT JOIN FolderTree parent
	ON (parent.id = ft.parent_folder_id AND ft.parent_folder_id IS NOT NULL);


/* ================================================================== */
/*  Query 5*/
/* ================================================================== */ 
## get "is_first_attempt" without creating a table 
## There are 85486 CYU quiz as first attempt

SELECT *,
CASE 
	WHEN first_time IS NOT NULL THEN 1
	ELSE 0 END AS 'is_first_attempt'
FROM (
	SELECT 
		first_finished_attempts.useraccount_id,
		first_finished_attempts.first_time,
		first_finished_attempts.section_folder_id
	FROM (
		SELECT
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
				tya.useraccount_id, tya.section_folder_id) first_finished_attempts) Myfirst;




/* ================================================================== */
/*  Query 6*/
/* ================================================================== */ 
## Join the result of Query 4 and 5 without creating a table

SELECT 
		MyY5table.useraccount_id,
		MyY5table.assessment_id,
		MyY5table.section_id,
		MyY5table.topic_id,
		MyY5table.test_type,
		MyY5table.is_finished,
		MyY5table.question_id,
		MyY5table.user_given_answer_id, 
		MyY5table.user_given_answer_text, 
		MyY5table.result,
		MyY5table.display_name_topic,
		MyY5table.display_name_section,
		MyY5table.time_attempted,
		MyY5table.time_finished,
        CASE 
		WHEN Myfirst.is_first_attempt IS NOT NULL THEN 1
		ELSE 0 END AS 'is_first_attempt'
FROM (
	SELECT 
		Y5table.useraccount_id,
		Y5table.assessment_id,
		parent.testyourself_section_folder_id AS 'section_id',
		Y5table.topic_id,
		Y5table.test_type,
		Y5table.is_finished,
		Y5table.question_id,
		Y5table.user_given_answer_id, 
		Y5table.user_given_answer_text, 
		Y5table.result,
		ft.display_name AS 'display_name_topic',
		parent.display_name AS 'display_name_section',
		Y5table.ts_created AS 'time_attempted',
		Y5table.ts_modified AS 'time_finished'

	FROM 
		(SELECT
			std.useraccount_id, 
			tya.id AS 'assessment_id', 
			tysq.video_id AS 'topic_id', 
			IF(	ISNULL(estimates.type), tya.test_type, estimates.type) AS 'test_type', 
			tya.is_finished, 
			tyaq.question_id, 
			tyaq.user_given_answer_id, 
			tyaq.user_given_answer_text, 
			tyaq.ts_created,
			tya.ts_modified,
			IF(	ISNULL(tyaq.user_given_answer_id) AND ISNULL(tyaq.user_given_answer_text), 99,
				IF(ISNULL(tyaq.user_given_answer_text),
					IF(tyaq.user_given_answer_id = tyq.correct_answer_id, 'correct', 'incorrect'), 'undefined')) 'result'
					
		FROM UserClusters std
		INNER JOIN TestYourselfAssessments tya
			ON std.useraccount_id = tya.useraccount_id
			AND (tya.test_type = 'sat') ## CheckYourUnderstanding
		INNER JOIN TestYourselfAssessmentQuestions tyaq
			ON tya.id = tyaq.assessment_id
			AND tya.is_finished = 1
		INNER JOIN TestYourselfSatQuestions tysq
			ON tyaq.question_id = tysq.question_id
			AND tya.section_folder_id = tysq.video_id
			AND tya.subject_id = tysq.subject_id
			AND tysq.subject_id = 1001 ## Need to change to more specific constricts
		INNER JOIN TestYourselfQuestions tyq
			ON tysq.question_id = tyq.id
		LEFT JOIN vll_estimates estimates
			ON estimates.assessment_id = tya.id
				AND estimates.type = 'sat' ## CheckYourUnderstanding
		WHERE(DATE(CONVERT_TZ(tya.ts_created, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE
			OR DATE(CONVERT_TZ(tya.ts_modified, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE)) Y5table
		
	INNER JOIN FolderTree ft
		ON ft.id = Y5table.topic_id
	LEFT JOIN FolderTree parent
		ON (parent.id = ft.parent_folder_id AND ft.parent_folder_id IS NOT NULL)) MyY5table

Left Join (
	SELECT *,
	CASE 
		WHEN first_time IS NOT NULL THEN 1
		ELSE 0 END AS 'is_first_attempt'
	FROM (
		SELECT 
			first_finished_attempts.useraccount_id,
			first_finished_attempts.first_time,
			first_finished_attempts.section_folder_id
		FROM (
			SELECT
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
					tya.useraccount_id, tya.section_folder_id) first_finished_attempts) the )Myfirst
   
ON MyY5table.useraccount_id = Myfirst.useraccount_id
AND MyY5table.section_id = Myfirst.section_folder_id
AND MyY5table.time_finished = Myfirst.first_time;



/* ================================================================== */
/*  Query 7*/
/* ================================================================== */ 
## Test the length of is_first_attempt
## Problem found:
## All is_first_attempt is 0
## There should be 85486 quizzes as 1

## ? New issue found:
## There are 246036 cases associated with 1,
## ----------140229 cases associated with 0.
## Becasue the 85486 are quizzes, and in each CYU quiz, there are 3 questions
## Therefore about 85486*3 = 256458 of the questions/items is first attempt
## 63.7% of the items were first attempt

SELECT Final.is_first_attempt, count(*)
FROM (
	SELECT 
			MyY5table.useraccount_id,
			MyY5table.assessment_id,
			MyY5table.section_id,
			MyY5table.topic_id,
			MyY5table.test_type,
			MyY5table.is_finished,
			MyY5table.question_id,
			MyY5table.user_given_answer_id, 
			MyY5table.user_given_answer_text, 
			MyY5table.result,
			MyY5table.display_name_topic,
			MyY5table.display_name_section,
			MyY5table.time_attempted,
			MyY5table.time_finished,
			CASE 
			WHEN Myfirst.is_first_attempt IS NOT NULL THEN 1
			ELSE 0 END AS 'is_first_attempt'
	FROM (
		SELECT 
			Y5table.useraccount_id,
			Y5table.assessment_id,
			parent.testyourself_section_folder_id AS 'section_id',
			Y5table.topic_id,
			Y5table.test_type,
			Y5table.is_finished,
			Y5table.question_id,
			Y5table.user_given_answer_id, 
			Y5table.user_given_answer_text, 
			Y5table.result,
			ft.display_name AS 'display_name_topic',
			parent.display_name AS 'display_name_section',
			Y5table.ts_created AS 'time_attempted',
			Y5table.ts_modified AS 'time_finished'

		FROM 
			(SELECT
				std.useraccount_id, 
				tya.id AS 'assessment_id', 
				tysq.video_id AS 'topic_id', 
				IF(	ISNULL(estimates.type), tya.test_type, estimates.type) AS 'test_type', 
				tya.is_finished, 
				tyaq.question_id, 
				tyaq.user_given_answer_id, 
				tyaq.user_given_answer_text, 
				tyaq.ts_created,
				tya.ts_modified,
				IF(	ISNULL(tyaq.user_given_answer_id) AND ISNULL(tyaq.user_given_answer_text), 99,
					IF(ISNULL(tyaq.user_given_answer_text),
						IF(tyaq.user_given_answer_id = tyq.correct_answer_id, 'correct', 'incorrect'), 'undefined')) 'result'
						
			FROM UserClusters std
			INNER JOIN TestYourselfAssessments tya
				ON std.useraccount_id = tya.useraccount_id
				AND (tya.test_type = 'sat') ## CheckYourUnderstanding
			INNER JOIN TestYourselfAssessmentQuestions tyaq
				ON tya.id = tyaq.assessment_id
				AND tya.is_finished = 1
			INNER JOIN TestYourselfSatQuestions tysq
				ON tyaq.question_id = tysq.question_id
				AND tya.section_folder_id = tysq.video_id
				AND tya.subject_id = tysq.subject_id
				AND tysq.subject_id = 1001 ## Need to change to more specific constricts
			INNER JOIN TestYourselfQuestions tyq
				ON tysq.question_id = tyq.id
			LEFT JOIN vll_estimates estimates
				ON estimates.assessment_id = tya.id
					AND estimates.type = 'sat' ## CheckYourUnderstanding
			WHERE(DATE(CONVERT_TZ(tya.ts_created, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE
				OR DATE(CONVERT_TZ(tya.ts_modified, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE)) Y5table
			
		INNER JOIN FolderTree ft
			ON ft.id = Y5table.topic_id
		LEFT JOIN FolderTree parent
			ON (parent.id = ft.parent_folder_id AND ft.parent_folder_id IS NOT NULL)) MyY5table

	Left Join (
		SELECT *,
		CASE 
			WHEN first_time IS NOT NULL THEN 1
			ELSE 0 END AS 'is_first_attempt'
		FROM (
			SELECT 
				first_finished_attempts.useraccount_id,
				first_finished_attempts.first_time,
				first_finished_attempts.section_folder_id
			FROM (
				SELECT
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
						tya.useraccount_id, tya.section_folder_id) first_finished_attempts) the )Myfirst
	   
	ON MyY5table.useraccount_id = Myfirst.useraccount_id
	AND MyY5table.topic_id = Myfirst.section_folder_id
	AND MyY5table.time_finished = Myfirst.first_time) Final
    GROUP BY is_first_attempt;

    
    

/* ================================================================== */
/*  Query 8-A*/
/* ================================================================== */ 
## A follow-up Analysis 
## There are 133619 CYU quizzes
## And 85486 CYU quizzes as first attempt, about 64%
## 133619 - 85486 = 48133 NOT the first attempt, about 36% 

SELECT
	tya.useraccount_id, 
	tya.ts_modified AS 'nonfirst_time', 
	tya.section_folder_id
FROM UserClusters uc
INNER JOIN TestYourselfAssessments tya
ON uc.useraccount_id = tya.useraccount_id
AND (tya.is_finished = 1)
AND (tya.test_type = 'sat')
AND DATE(CONVERT_TZ(tya.ts_modified, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE;




/* ================================================================== */
/*  Query 8-B*/
/* ================================================================== */ 

SELECT 	a.useraccount_id,
		a.nonfirst_time, 
		a.section_folder_id,
        b.mina
FROM
        (SELECT
				tya.useraccount_id, 
				-- min(tya.ts_modified) as mina,
                tya.ts_modified AS 'nonfirst_time', 
				tya.section_folder_id
		FROM UserClusters uc
		INNER JOIN TestYourselfAssessments tya
		ON uc.useraccount_id = tya.useraccount_id
		AND (tya.is_finished = 1)
		AND (tya.test_type = 'sat')
		AND DATE(CONVERT_TZ(tya.ts_modified, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE) a
                    
Left JOIN      
		(SELECT
				tya.useraccount_id, 
				min(tya.ts_modified) as mina,
                tya.ts_modified AS 'nonfirst_time', 
				tya.section_folder_id
		FROM UserClusters uc
		INNER JOIN TestYourselfAssessments tya
		ON uc.useraccount_id = tya.useraccount_id
		AND (tya.is_finished = 1)
		AND (tya.test_type = 'sat')
		AND DATE(CONVERT_TZ(tya.ts_modified, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE
		GROUP BY tya.useraccount_id, tya.section_folder_id)b
ON a.useraccount_id= b.useraccount_id
AND a.nonfirst_time = b.nonfirst_time
AND a.section_folder_id = b.section_folder_id;


/* ================================================================== */
/*  Query 9*/
/* ================================================================== */ 
## A follow-up Analysis 

SELECT *,
CASE 
	WHEN difference <> 0 OR difference IS NULL THEN 999
	ELSE 1 END AS 'is_nonfirst_attempt'
FROM (
	SELECT *
	FROM (
    SELECT a.useraccount_id,
			   a.nonfirst_time, 
			   a.section_folder_id,
               b.mina,
               UNIX_TIMESTAMP(a.nonfirst_time) - UNIX_TIMESTAMP(b.mina) AS difference
        FROM
        (SELECT
				tya.useraccount_id, 
				-- min(tya.ts_modified) as mina,
                tya.ts_modified AS 'nonfirst_time', 
				tya.section_folder_id
		FROM UserClusters uc
		INNER JOIN TestYourselfAssessments tya
		ON uc.useraccount_id = tya.useraccount_id
		AND (tya.is_finished = 1)
		AND (tya.test_type = 'sat')
		AND DATE(CONVERT_TZ(tya.ts_modified, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE) a
                    
		Left join          
		(SELECT
				tya.useraccount_id, 
				min(tya.ts_modified) as mina,
                tya.ts_modified AS 'nonfirst_time', 
				tya.section_folder_id
		FROM UserClusters uc
		INNER JOIN TestYourselfAssessments tya
		ON uc.useraccount_id = tya.useraccount_id
		AND (tya.is_finished = 1)
		AND (tya.test_type = 'sat')
		AND DATE(CONVERT_TZ(tya.ts_modified, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE
		GROUP BY tya.useraccount_id, tya.section_folder_id)b
ON a.useraccount_id= b.useraccount_id
AND a.nonfirst_time = b.nonfirst_time
AND a.section_folder_id = b.section_folder_id) first_finished_attempts) Myfirst;
                



/* ================================================================== */
/*  Query 10*/
/* ================================================================== */ 
## Join the result of Query 5 and Query 6 without creating a table
## The final query

## 15 variables:  
## 1. useraccount_id
## 2. assessment_id
## 3. section_id 
## 4. topic_id
## 5. test_type
## 6. is_finishes
## 7. question_id
## 8. user_given_answer_id
## 9. user_given_answer_text
## 10. result
## 11. display_name_section 
## 12. display_name_topic
## 13. time_attempted
## 14. time_finished
## 15. is_first_attempt

SELECT 
		MyY5table.useraccount_id,
		MyY5table.assessment_id,
		MyY5table.section_id,
		MyY5table.topic_id,
		MyY5table.test_type,
		MyY5table.is_finished,
		MyY5table.question_id,
		MyY5table.user_given_answer_id, 
		MyY5table.user_given_answer_text, 
		MyY5table.result,
		MyY5table.display_name_topic,
		MyY5table.display_name_section,
		MyY5table.time_attempted,
		MyY5table.time_finished,
        CASE 
		WHEN Myfirst.is_first_attempt IS NOT NULL THEN 1
		ELSE 0 END AS 'is_first_attempt'
FROM (
	SELECT 
		Y5table.useraccount_id,
		Y5table.assessment_id,
		parent.testyourself_section_folder_id AS 'section_id',
		Y5table.topic_id,
		Y5table.test_type,
		Y5table.is_finished,
		Y5table.question_id,
		Y5table.user_given_answer_id, 
		Y5table.user_given_answer_text, 
		Y5table.result,
		ft.display_name AS 'display_name_topic',
		parent.display_name AS 'display_name_section',
		Y5table.ts_created AS 'time_attempted',
		Y5table.ts_modified AS 'time_finished'

	FROM 
		(SELECT
			std.useraccount_id, 
			tya.id AS 'assessment_id', 
			tysq.video_id AS 'topic_id', 
			IF(	ISNULL(estimates.type), tya.test_type, estimates.type) AS 'test_type', 
			tya.is_finished, 
			tyaq.question_id, 
			tyaq.user_given_answer_id, 
			tyaq.user_given_answer_text, 
			tyaq.ts_created,
			tya.ts_modified,
			IF(	ISNULL(tyaq.user_given_answer_id) AND ISNULL(tyaq.user_given_answer_text), 99,
				IF(ISNULL(tyaq.user_given_answer_text),
					IF(tyaq.user_given_answer_id = tyq.correct_answer_id, 'correct', 'incorrect'), 'undefined')) 'result'
					
		FROM UserClusters std
		INNER JOIN TestYourselfAssessments tya
			ON std.useraccount_id = tya.useraccount_id
			AND (tya.test_type = 'sat') ## CheckYourUnderstanding
		INNER JOIN TestYourselfAssessmentQuestions tyaq
			ON tya.id = tyaq.assessment_id
			AND tya.is_finished = 1
		INNER JOIN TestYourselfSatQuestions tysq
			ON tyaq.question_id = tysq.question_id
			AND tya.section_folder_id = tysq.video_id
			AND tya.subject_id = tysq.subject_id
			AND tysq.subject_id = 1001 ## Need to change to more specific constricts
		INNER JOIN TestYourselfQuestions tyq
			ON tysq.question_id = tyq.id
		LEFT JOIN vll_estimates estimates
			ON estimates.assessment_id = tya.id
				AND estimates.type = 'sat' ## CheckYourUnderstanding
		WHERE(DATE(CONVERT_TZ(tya.ts_created, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE
			OR DATE(CONVERT_TZ(tya.ts_modified, 'GMT', 'EST')) BETWEEN @START_DATE AND @END_DATE)) Y5table
		
	INNER JOIN FolderTree ft
		ON ft.id = Y5table.topic_id
	LEFT JOIN FolderTree parent
		ON (parent.id = ft.parent_folder_id AND ft.parent_folder_id IS NOT NULL)) MyY5table

Left Join (
	SELECT *,
	CASE 
		WHEN first_time IS NOT NULL THEN 1
		ELSE 0 END AS 'is_first_attempt'
	FROM (
		SELECT 
			first_finished_attempts.useraccount_id,
			first_finished_attempts.first_time,
			first_finished_attempts.section_folder_id
		FROM (
			SELECT
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
					tya.useraccount_id, tya.section_folder_id) first_finished_attempts) the )Myfirst
   
ON MyY5table.useraccount_id = Myfirst.useraccount_id
AND MyY5table.topic_id = Myfirst.section_folder_id
AND MyY5table.time_finished = Myfirst.first_time;


