## Functional requirements

### 1. Authentication

**FR-1: Creator registration**

* A user can create an account using an email and password.
* Email must be unique.
* Password must satisfy a basic minimum length.

**FR-2: Creator login**

* A registered creator can log in using email and password.
* An authenticated creator remains signed in between application sessions.

**FR-3: Creator logout**

* A creator can log out.

You can deliberately leave out:

* Social login
* Email verification
* Password reset
* Multi-factor authentication
* Profile management

Those are not necessary for the class project.

---

### 2. Survey dashboard

The dashboard is the main page after authentication.

**FR-4: View surveys**

* The creator can view surveys they have created.
* Each survey displays:

   * Title
   * Description
   * Number of responses
   * Created date
   * Last modified date

**FR-5: Create survey**

* The creator can start a new survey from the dashboard.

**FR-6: Edit survey**

* The creator can open an existing survey and modify its questions/settings.

**FR-7: Delete survey**

* The creator can delete a survey.
* The application should ask for confirmation before deletion.

**FR-8: View responses**

* The creator can select a survey and view its responses.

---

### 3. Survey builder

This is probably the most important feature of QuickSurveys.

**FR-9: Set survey information**

* Creator can define:

   * Survey title
   * Description

**FR-10: Add questions**

* Creator can add questions to a survey.

For the class project, I would limit question types to perhaps:

1. Short answer
2. Paragraph
3. Multiple choice
4. Checkboxes
5. Linear scale

You could start with only the first four if you want to reduce scope.

**FR-11: Configure questions**

* Creator can:

   * Edit question text
   * Mark a question as required
   * Configure options where applicable
   * Delete a question

**FR-12: Reorder questions**

* Creator can change the order of questions.

Flutter's drag-and-drop functionality makes this a nice feature for the project without requiring a complicated backend.

**FR-13: Survey settings**
Creator can configure:

```text
Allow anonymous responses:     Yes / No
Require respondent name:       Yes / No
Require respondent email:      Yes / No
```

You could later add a setting for limiting one response per email, but I would leave it out initially.

**FR-14: Save survey**

* Creator can save a survey as a draft.
* A saved survey can later be edited.

**FR-15: Publish survey**

* Creator can publish a survey.
* A published survey receives a shareable URL.

For example:

```text
https://quicksurveys.app/survey/abc123
```

---

### 4. Responding to surveys

**FR-16: Open survey from link**

* Anyone with a valid survey link can view the published survey.

**FR-17: Survey availability**

* Unpublished or deleted surveys cannot receive responses.
* The respondent should see an appropriate message if the survey is unavailable.

**FR-18: Anonymous response**

* If anonymous responses are enabled, a respondent can submit without signing in.

**FR-19: Required respondent information**

* If the creator requires a name, the respondent must provide one.
* If the creator requires an email, the respondent must provide one.

**FR-20: Validate answers**

* Required questions must be answered.
* Answers must conform to the question type.

**FR-21: Submit response**

* A respondent can submit their completed survey.
* The application displays a confirmation after successful submission.

Something simple like:

```text
Thank you!

Your response has been recorded.
```

---

### 5. Response analysis

**FR-22: View response count**

* Creator can see the total number of responses.

**FR-23: Visualize closed-ended responses**
For multiple-choice, checkbox, and scale questions, display appropriate charts.

For example:

```text
How satisfied are you?

Very dissatisfied  ███
Dissatisfied       █████
Neutral            █████████
Satisfied          ███████████████
Very satisfied     ███████████████████
```

Or use `fl_chart` for pie/bar charts.

**FR-24: View individual responses**

* Creator can browse submitted responses.
* Individual answers can be viewed together.

**FR-25: View open-ended responses**

* Short-answer and paragraph responses can be displayed in a list.
* Creator can read each response.

You could have a response page structured as:

```text
Responses: 42

[Overview] [Individual Responses]

Overview
─────────────────────────────

How satisfied are you?
[Bar Chart]

Which feature do you use most?
[Pie Chart]

What could we improve?
─────────────────────────────
"Better mobile support."

"More customization options."

"The UI is easy to use."
```

---

### 6. Sharing

**FR-26: Copy survey link**

* Creator can copy the published survey URL.

**FR-27: Access survey without dashboard**

* Respondents should not need access to the creator's dashboard.

This separation is important:

```text
Creator

Login
  ↓
Dashboard
  ↓
Survey Builder
  ↓
Publish
  ↓
Share Link
       ↓
       ↓
       ↓
Respondent
       ↓
Survey Page
       ↓
Submit Response
```
