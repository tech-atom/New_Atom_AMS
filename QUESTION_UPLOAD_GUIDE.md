# 📝 Question Paper Upload Guide

## Supported Question Types

Your exam system supports **5 different question types**:

### 1. **MCQ (Multiple Choice Questions)** ✅
Standard multiple choice with 4 options (A, B, C, D)

**Format:**
```
Question Type: mcq
Question: What is 2 + 2?
Option A: 3
Option B: 4
Option C: 5
Option D: 6
Correct Answer: B
Explanation: Basic addition
```

---

### 2. **True/False Questions** ✅
Binary choice questions

**Format:**
```
Question Type: true_false
Question: The sky is blue.
Option A: True
Option B: False
Correct Answer: True
Explanation: Sky appears blue due to Rayleigh scattering
```

---

### 3. **Image-Based MCQ** 🖼️
Multiple choice questions with an accompanying image

**Format:**
```
Question Type: image_mcq
Question: Identify the animal in the image
Option A: Dog
Option B: Cat
Option C: Lion
Option D: Tiger
Correct Answer: B
Image File: animal_photo.jpg
Explanation: This is a domestic cat
```

**Note:** Upload the image separately when creating the question in the system.

---

### 4. **Descriptive Questions** 📄
Open-ended text answers (essay-style)

**Format:**
```
Question Type: descriptive
Question: Explain the theory of relativity in your own words.
Explanation/Instructions: Write 300-500 words. Include examples. Time limit: 15 minutes.
```

**No options or correct answers needed** - manually graded by instructor.

---

### 5. **Video Response Questions** 🎥
Students record video answers

**Format:**
```
Question Type: video_response
Question: Introduce yourself and explain your career goals.
Instructions: Record 2-3 minute video. Speak clearly. Look at camera. Be professional.
```

**No options or correct answers needed** - reviewed by instructor.

---

## 📊 CSV Template Structure

Use the provided `sample_questions_template.csv` file as a reference.

**Column Headers:**
1. **Question Type** - mcq | true_false | image_mcq | descriptive | video_response
2. **Question Text** - The actual question
3. **Option A** - First option (leave empty for descriptive/video)
4. **Option B** - Second option (leave empty for descriptive/video)
5. **Option C** - Third option (MCQ only, leave empty for others)
6. **Option D** - Fourth option (MCQ only, leave empty for others)
7. **Correct Answer** - A, B, C, D, True, or False (leave empty for descriptive/video)
8. **Explanation/Instructions** - Explanation for answer OR instructions for video/descriptive

---

## 🎯 Quick Reference Table

| Question Type | Options Needed? | Correct Answer? | Image Upload? | Notes |
|---------------|----------------|-----------------|---------------|-------|
| mcq | ✅ Yes (A,B,C,D) | ✅ Yes | ❌ No | Standard MCQ |
| true_false | ✅ Yes (True/False) | ✅ Yes | ❌ No | Binary choice |
| image_mcq | ✅ Yes (A,B,C,D) | ✅ Yes | ✅ Yes | Upload image separately |
| descriptive | ❌ No | ❌ No | ❌ No | Manually graded |
| video_response | ❌ No | ❌ No | ❌ No | Recorded by student |

---

## 📝 Sample Questions for Each Type

### MCQ Example:
```csv
mcq,"What is the speed of light?","299,792 km/s","300,000 km/s","150,000 km/s","500,000 km/s",A,"Approximately 299,792 kilometers per second in vacuum"
```

### True/False Example:
```csv
true_false,"Water boils at 100°C at sea level.",True,False,,,True,"At standard atmospheric pressure (1 atm), water boils at 100 degrees Celsius"
```

### Image MCQ Example:
```csv
image_mcq,"What programming language logo is shown?",Python,Java,JavaScript,Ruby,A,"Upload the Python logo image separately. The two intertwined snakes are distinctive."
```

### Descriptive Example:
```csv
descriptive,"Explain the causes and effects of climate change.",,,,,,"Write a comprehensive essay covering: greenhouse gases, fossil fuels, deforestation, temperature rise, sea level rise, extreme weather. Minimum 400 words. Time: 20 minutes."
```

### Video Response Example:
```csv
video_response,"Demonstrate proper hand-washing technique.",,,,,,"Record 2-minute video showing: wet hands, apply soap, scrub for 20 seconds, rinse, dry. Explain importance of hygiene. WHO guidelines preferred."
```

---

## 🚀 How to Use This Template

### Option 1: Manual Entry (Current System)
1. Log in as Admin
2. Go to "Create Exam"
3. Fill in exam details (title, subject, time limit)
4. Upload question paper document (this template or your own)
5. Click "Add Question" for each question
6. Select question type from dropdown
7. Fill in question text, options, correct answer
8. Add explanation/instructions
9. For image_mcq: Upload image file
10. Click "Create Exam"

### Option 2: Bulk Upload (Future Feature)
Save this CSV file with your questions and upload it directly to create all questions at once.

---

## ✅ Best Practices

1. **Be Clear and Concise** - Questions should be unambiguous
2. **Provide Context** - Add explanations for learning purposes
3. **Mix Question Types** - Combine different types for comprehensive assessment
4. **Set Appropriate Time Limits** - Especially for descriptive and video questions
5. **Test Your Questions** - Review for typos and correct answers
6. **Use Proper Grammar** - Professional presentation matters
7. **Add Images Wisely** - For image_mcq, ensure images are clear and relevant
8. **Video Instructions** - Be specific about duration and requirements
9. **Descriptive Grading** - Include rubric or key points in explanation

---

## 📁 File Formats Supported

**For Question Papers:**
- PDF (.pdf)
- Word Documents (.doc, .docx)
- Text Files (.txt)
- Images (.jpg, .jpeg, .png)
- Excel (.xlsx, .xls)
- PowerPoint (.ppt, .pptx)

**For Question Images (image_mcq):**
- JPEG (.jpg, .jpeg)
- PNG (.png)
- GIF (.gif)

---

## 💡 Pro Tips

### For MCQ Questions:
- Make all options plausible
- Avoid "all of the above" or "none of the above"
- Keep options similar in length
- Don't use negative wording unless necessary

### For True/False:
- Avoid absolute terms like "always" or "never"
- Make statements clear and unambiguous
- Provide educational explanations

### For Descriptive:
- Set word count ranges
- Provide time estimates
- List key points expected in answer
- Consider partial credit rubrics

### For Video Response:
- Specify exact time duration
- List what should be included
- Mention if props/materials needed
- Set professional expectations

---

## 🎓 Example Complete Exam Structure

**Exam Title:** Web Development Fundamentals Assessment  
**Subject:** Computer Science  
**Time Limit:** 60 minutes  
**Structure:**
- 15 MCQ questions (30 points)
- 5 True/False questions (10 points)
- 2 Image MCQ questions (10 points)
- 2 Descriptive questions (30 points)
- 1 Video response (20 points)

**Total:** 25 questions, 100 points

---

## 📞 Need Help?

If you encounter issues:
1. Check question type spelling (must be exact)
2. Ensure correct answer matches option letter
3. Verify CSV format is correct
4. For image_mcq, upload images after creating question
5. Leave option fields empty for descriptive/video types

---

**Last Updated:** December 19, 2025  
**System Version:** Cognitio Pro LMS v2.0
