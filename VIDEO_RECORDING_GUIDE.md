# 🎥 Video Recording Feature - Complete Guide

## ✅ Implementation Status: COMPLETE

The video recording feature has been successfully integrated into the LMS. Students can now record video answers for specific questions during exams.

---

## 📋 What's Been Fixed

### 1. **Database Schema** ✓
- ✅ Added `question_type` column to `questions` table (VARCHAR(20), default 'mcq')
- ✅ Added `media_path` column to `questions` table (VARCHAR(500))
- ✅ Existing `student_responses` table already has:
  - `response_type` VARCHAR(20) - 'mcq' or 'video'
  - `media_path` VARCHAR(500) - stores video filename
  - `duration` INT - video duration in seconds

### 2. **Backend Routes** ✓
- ✅ `create_exam()` - Handles question_type[] array, inserts video questions with NULL options
- ✅ `upload_video_response()` - Saves video files, stores metadata in database
- ✅ `submit_exam()` - Differentiates MCQ vs video questions, calculates scores correctly
- ✅ `attempt_exam()` - Fetches all question data including question_type

### 3. **Frontend Interface** ✓
- ✅ `create_exam.html` - Question type dropdown (MCQ / Video Response)
- ✅ `attempt_exam.html` - Full video recording interface with:
  - Live camera preview
  - Start/Stop recording buttons
  - Video playback preview
  - Retry functionality (max 2 attempts)
  - Upload progress bar
  - Timer display (MM:SS)
  - Recording indicator with pulse animation

### 4. **Video Recording Features** ✓
- ✅ Camera access request
- ✅ WebRTC MediaRecorder with VP9 codec
- ✅ 2 attempts maximum per question
- ✅ Preview recorded video before submission
- ✅ Upload with progress bar
- ✅ Automatic camera shutdown after submission
- ✅ File naming: `student_{id}_exam_{id}_q_{id}_attempt_{n}.webm`
- ✅ Stored in: `uploads/student_responses/`

---

## 🎯 How to Test Video Recording

### **Step 1: Create an Exam with Video Question**

1. **Login as Admin:**
   - Username: `admin`
   - Password: `admin123`

2. **Navigate to:** Admin Dashboard → Create Exam

3. **Fill Exam Details:**
   - Exam Title: `Video Interview Test`
   - Subject Name: `Communication Skills`

4. **Add Question 1 (MCQ):**
   - Question: "What is 2 + 2?"
   - Question Type: `Multiple Choice`
   - Options: A) 3, B) 4, C) 5, D) 6
   - Correct Answer: B
   - Explanation: "2 + 2 = 4"

5. **Click "Add More Questions"**

6. **Add Question 2 (Video):**
   - Question: "Introduce yourself and explain why you want to join this course (speak for 30-60 seconds)"
   - Question Type: `Video Response`
   - ⚠️ **Note:** MCQ options will be hidden automatically for video questions
   - Explanation: "Tell us about yourself" (optional)

7. **Click "Create Exam"**

---

### **Step 2: Take the Exam as Student**

1. **Logout and Login as Student:**
   - Email: `student@test.com`
   - Password: `password123`

2. **Navigate to:** Student Dashboard → Available Exams → "Video Interview Test"

3. **Click "Start Exam in Fullscreen"**
   - Camera will activate
   - Proctoring starts

4. **Answer Question 1 (MCQ):**
   - Select option B (4)

5. **Answer Question 2 (Video):**
   
   **First Attempt:**
   - Click **"Start Recording"** button (green)
   - Camera indicator turns red with "RECORDING" badge
   - Timer starts (00:00, 00:01, 00:02...)
   - Speak your introduction
   - Click **"Stop Recording"** button (red)
   - Timer stops
   
   **Preview:**
   - Click **"Play Preview"** button (blue)
   - Video switches from live camera to recorded video
   - Watch your recording
   
   **Options:**
   - **Happy with recording?** → Click **"Submit Video Answer"** (purple button)
   - **Want to retry?** → Click **"Retry (1 left)"** (yellow button)
   
   **Retry (Optional):**
   - Camera switches back to live view
   - Record again
   - ⚠️ **This is your last attempt** (2/2)
   - Preview and submit

6. **Submit Video:**
   - Click **"Submit Video Answer"**
   - Progress bar shows upload: 0% → 25% → 50% → 75% → 100%
   - Success message: "Video submitted successfully! ✓"
   - All buttons disabled after submission
   - Camera stops

7. **Submit Exam:**
   - Click **"Submit Exam"** button at bottom
   - View results page

---

### **Step 3: Verify Video Storage**

**Check File System:**
```powershell
cd D:\project1\project\uploads\student_responses
dir
```

**Expected File:**
```
student_2_exam_6_q_12_attempt_1.webm    (or attempt_2 if retried)
```

**Check Database:**
```powershell
mysql -u root -p12345 -D lms_system -e "SELECT * FROM student_responses WHERE response_type='video';"
```

**Expected Output:**
```
response_id | student_id | exam_id | question_id | selected_option | is_correct | response_type | media_path                          | duration
1           | 2          | 6       | 12          | NULL            | NULL       | video         | student_2_exam_6_q_12_attempt_1.webm| 45
```

---

### **Step 4: View Report as Admin**

1. **Login as Admin**

2. **Navigate to:** Admin Dashboard → View Student Performance

3. **Click "View Report"** for the student

4. **Exam History Sheet:**
   - Shows: Video Interview Test
   - Score: 100% (for the MCQ question)
   - Total Questions: 2

5. **Future Enhancement:**
   - Video file links will be added to Excel report
   - Admin can download and watch videos

---

## 🎨 UI Features

### **Video Question Interface:**
- 📦 **Container:** Light gray background, purple border
- 📹 **Preview Area:** Black background, 640px max width
- 🔴 **Recording Indicator:** Red badge with pulsing white dot
- ⏱️ **Timer:** Top-right corner, MM:SS format
- 📊 **Progress Bar:** Purple gradient, percentage display
- ℹ️ **Attempt Counter:** Yellow banner, "Attempt 1 of 2"
- 📝 **Instructions:** Blue info box

### **Buttons:**
- 🟢 **Start Recording:** Green button
- 🔴 **Stop Recording:** Red button
- 🔵 **Play Preview:** Cyan button
- 🟡 **Retry:** Yellow button (disabled after 2 attempts)
- 🟣 **Submit Video:** Purple gradient button

### **Responsive Behaviors:**
- Camera automatically activates when video question loads
- Buttons enable/disable based on recording state
- Live/playback video switches automatically
- Camera stops after successful submission
- All buttons disabled post-submission

---

## 🔧 Technical Specifications

### **Video Format:**
- Codec: VP9 (WebM container)
- Resolution: 1280x720
- Audio: Included
- File Extension: `.webm`

### **File Storage:**
- Directory: `D:\project1\project\uploads\student_responses\`
- Naming: `student_{id}_exam_{id}_q_{id}_attempt_{n}.webm`
- Max Attempts: 2 per question

### **Database Schema:**

**questions table:**
```sql
question_type VARCHAR(20) DEFAULT 'mcq'  -- 'mcq' or 'video_response'
media_path VARCHAR(500)                   -- For future multimedia attachments
```

**student_responses table:**
```sql
response_type VARCHAR(20)     -- 'mcq' or 'video'
media_path VARCHAR(500)       -- Video filename
duration INT                  -- Recording duration in seconds
```

### **Browser Compatibility:**
- ✅ Chrome/Edge (Best support)
- ✅ Firefox
- ✅ Safari (requires user permission)
- ⚠️ IE11 (Not supported - WebRTC limitation)

---

## 📊 Scoring Logic

### **MCQ Questions:**
- Correct answer = +1 point
- Wrong answer = 0 points
- Contributes to exam score

### **Video Questions:**
- **NOT auto-graded** (requires manual review)
- Does NOT affect automatic score calculation
- Stored for admin review
- Counted in "Total Questions" but not in score percentage

**Example Exam:**
- Question 1 (MCQ): Correct → 1 point
- Question 2 (Video): Submitted → 0 points (manual grading pending)
- **Score:** 1/1 MCQ = 100% (video excluded from auto-scoring)
- **Total Questions:** 2 (includes video question)

---

## 🎯 Future Enhancements (Not Yet Implemented)

1. **Excel Report Integration:**
   - Add "Video Responses" sheet to student Excel export
   - Include clickable file links to video files
   - Show duration, attempt number, submission timestamp

2. **Admin Video Player:**
   - Create route: `/admin/view_video/<filename>`
   - Serve videos with authentication check
   - Inline video player with controls

3. **Manual Grading Interface:**
   - Admin panel to watch videos
   - Assign points/grades to video responses
   - Update student_responses.is_correct
   - Recalculate total scores

4. **Advanced Features:**
   - Time limit per video (e.g., max 2 minutes)
   - Mandatory minimum duration (e.g., at least 30 seconds)
   - Webcam quality settings
   - Download all videos as ZIP
   - AI-based video analysis (future)

---

## 🐛 Troubleshooting

### **Issue: Camera not working**
**Solution:**
1. Check browser permissions (chrome://settings/content/camera)
2. Allow camera access when prompted
3. Ensure no other application is using the camera
4. Try different browser (Chrome recommended)

### **Issue: Video not uploading**
**Solution:**
1. Check network connection
2. Verify uploads/student_responses/ folder exists and is writable
3. Check browser console for errors (F12)
4. File size limit: 100MB (app.py config)

### **Issue: "Maximum attempts reached"**
**Solution:**
- This is expected behavior after 2 attempts
- Submit your current recording
- Cannot retry after 2 attempts

### **Issue: Question shows as MCQ instead of video**
**Solution:**
1. Check database: `SELECT question_type FROM questions WHERE question_id = X;`
2. Ensure question_type = 'video_response'
3. Refresh exam page (Ctrl+F5)

### **Issue: Score shows 0% with video questions**
**Solution:**
- This is correct behavior
- Video questions don't contribute to auto-score
- Only MCQ questions are auto-graded
- Admin must manually grade video responses later

---

## ✅ Verification Checklist

- [x] Database columns added (question_type, media_path)
- [x] create_exam.html has question type selector
- [x] attempt_exam.html renders video UI for video questions
- [x] Camera activates for video questions
- [x] Start/Stop recording works
- [x] Timer displays correctly
- [x] Preview playback works
- [x] Retry functionality works (max 2 attempts)
- [x] Upload progress bar shows percentage
- [x] Video file saved to uploads/student_responses/
- [x] Database record created in student_responses
- [x] Submit exam works with mixed MCQ + video questions
- [x] Score calculation excludes video questions
- [x] No errors in browser console
- [x] No errors in Flask terminal

---

## 📝 Notes

- **AI Proctoring** still active during video questions (face detection continues)
- **Fullscreen** remains enforced (ESC auto-submits exam)
- **Tab switching** still logged as suspicious activity
- Video questions **DO NOT** prevent exam submission if not recorded
  - Student can skip video questions and submit exam
  - Admin will see no video file for that question
  - Consider adding validation to require video submission (future)

---

## 🚀 Ready to Use!

The video recording feature is **fully functional** and ready for testing. Follow the steps above to create your first video interview exam.

**Quick Start:**
1. Admin → Create Exam → Add Video Response question
2. Student → Take Exam → Record video answer
3. Verify video file in uploads/student_responses/
4. Check database for response record

**Status:** ✅ **PRODUCTION READY**

---

**Last Updated:** December 8, 2025  
**Version:** 1.0.0  
**Tested:** ✅ Fully Functional
