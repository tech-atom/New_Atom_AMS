# Score Visibility Control Feature ✅

## Overview
Admins can now control whether students can see their exam scores or not. This gives you flexibility in managing when and how results are revealed to students.

## Features Added

### 1. **Admin Control Panel**
- New "Score Visibility" column in Manage Exams page
- Toggle button for each exam with visual indicators:
  - 👁️ **Visible** (Green) - Students can see their scores
  - 🚫 **Hidden** (Purple) - Scores are hidden from students

### 2. **Student Experience**
- **When scores are visible**: Students see their complete results including:
  - Score percentage with animated circle
  - Total questions, correct, and incorrect answers
  - Performance feedback messages
  
- **When scores are hidden**: Students see:
  - Exam submission confirmation
  - Message that scores are being evaluated
  - Total number of questions only
  - Clear notification that admin has disabled score visibility

### 3. **Database Changes**
- Added `show_scores` column to `exam` table
- Default value: `1` (scores visible)
- Values: `1` = visible, `0` = hidden

## How to Use

### For Admins:
1. Navigate to **Manage Exams** page
2. Find the exam you want to configure
3. Look for the **Score Visibility** column
4. Click the toggle button to switch between:
   - **Visible** - Students can see scores immediately
   - **Hidden** - Scores are kept private until you enable them

### For Students:
- When taking an exam, students will automatically see the appropriate result page based on admin settings
- If scores are hidden, they'll see a friendly message explaining that results are being evaluated

## Setup Instructions

### Update Your Database:
Run the following SQL command in your MySQL database:

```sql
ALTER TABLE exam ADD COLUMN IF NOT EXISTS show_scores TINYINT(1) DEFAULT 1;
UPDATE exam SET show_scores = 1 WHERE show_scores IS NULL;
```

Or simply run the provided update script:
```bash
mysql -u your_username -p your_database_name < update_score_visibility.sql
```

## Use Cases

1. **Delayed Results**: Hide scores until all students complete the exam
2. **Manual Review**: Hide scores for exams requiring manual grading
3. **Controlled Release**: Reveal scores during a specific class/meeting
4. **Subjective Assessments**: Hide scores for exams with essay questions pending review

## Technical Details

### Files Modified:
- `app.py` - Added toggle endpoint and visibility check
- `setup_database.sql` - Added show_scores column
- `manage_exams.html` - Added toggle button UI
- `exam_result.html` - Conditional score display

### New Endpoint:
- `POST /admin/toggle_score_visibility/<exam_id>` - Toggles score visibility for an exam

### Logic Flow:
1. Admin clicks toggle button
2. Backend flips the `show_scores` value (0↔1)
3. When student completes exam, system checks `show_scores`
4. Appropriate result page is displayed based on setting

## Benefits

✅ **Flexibility** - Control when students see results  
✅ **Fairness** - Prevent early students from sharing scores  
✅ **Review Time** - Allow time for manual verification  
✅ **Communication** - Manage expectations with clear messaging  
✅ **Privacy** - Keep scores confidential when needed

---

**Status**: ✅ Fully Implemented and Ready to Use
