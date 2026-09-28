# QuickSurveys Firestore Database Plan

## Overview

If QuickSurveys were implemented using Firebase Firestore, the application
would use three main collections to store and organize its data:

1. `users` - Stores information about survey creators.
2. `surveys` - Stores survey information and questions.
3. `responses` - Stores responses submitted to surveys.

The purpose of separating the data into these collections is to keep user
information, survey definitions, and submitted responses organized and easy
to access.

Firebase Authentication would be used separately to manage user
authentication and passwords.

---

# 1. Surveys Collection

## Purpose

The `surveys` collection stores surveys created by users.

Each survey would be represented by one Firestore document. The document ID
would be the unique survey ID and could also be used when generating a
shareable survey URL.

## Example Document

```text
surveys
└── surveyId
    ├── title
    ├── description
    ├── isPublished
    ├── allowAnonymousResponses
    ├── requireRespondentName
    ├── requireRespondentEmail
    ├── createdBy
    ├── createdAt
    ├── updatedAt
    └── questions
Fields
Field	Type	Purpose
title	String	Title of the survey
description	String	Description of the survey
isPublished	Boolean	Determines whether the survey has been published
allowAnonymousResponses	Boolean	Determines whether respondents can submit anonymously
requireRespondentName	Boolean	Determines whether the respondent must provide their name
requireRespondentEmail	Boolean	Determines whether the respondent must provide their email
createdBy	String	ID of the user who created the survey
createdAt	Timestamp	Time the survey was created
updatedAt	Timestamp	Time the survey was last modified
questions	Array	Questions belonging to the survey
Questions

The questions field would contain the questions belonging to the survey.

Each question could contain:

question
├── id
├── text
├── type
├── isRequired
├── options
├── scaleMin
├── scaleMax
├── scaleMinLabel
└── scaleMaxLabel

The type field would identify the type of question.

Supported question types are:

Short answer
Paragraph
Multiple choice
Checkboxes
Linear scale

For multiple-choice and checkbox questions, the options field would contain
the available answer choices.

For linear-scale questions, the scale fields would define the minimum,
maximum, and labels for the scale.

2. Responses Collection
Purpose

The responses collection stores responses submitted by respondents.

Each submitted response would be stored as a separate Firestore document.

A response would contain the ID of the survey that it belongs to, allowing
the application to retrieve all responses for a specific survey.

Example Document
responses
└── responseId
    ├── surveyId
    ├── respondentId
    ├── respondentName
    ├── respondentEmail
    ├── submittedAt
    └── answers
Fields
Field	Type	Purpose
surveyId	String	Identifies the survey that was answered
respondentId	String	Identifies the respondent when applicable
respondentName	String	Name of the respondent when required or provided
respondentEmail	String	Email of the respondent when required or provided
submittedAt	Timestamp	Time the response was submitted
answers	Array	Contains the answers submitted by the respondent
Answers

Each answer would reference the question that it belongs to.

answer
├── questionId
└── value

For example:

answers:
[
    {
        questionId: "question1",
        value: "Flutter is great"
    },
    {
        questionId: "question2",
        value: ["Flutter", "Firebase"]
    }
]

The questionId allows the application to connect each answer to the
appropriate question in the survey.

3. Users Collection
Purpose

The users collection stores information about users who create and manage
surveys.

Authentication, including passwords, would be handled by Firebase
Authentication. Firestore would store additional application-specific
information about the user.

Passwords would not be stored in the users collection.

Example Document
users
└── userId
    ├── name
    ├── email
    ├── createdAt
    └── surveyIds
Fields
Field	Type	Purpose
name	String	User's display name
email	String	User's email address
createdAt	Timestamp	Time the account was created
surveyIds	Array	IDs of surveys created by the user
Authentication

Firebase Authentication would manage the user's authentication information.

This would include:

User account creation
Email/password authentication
Password storage
Login and logout
Password reset

Firestore would not store the user's password.

The Firebase Authentication user ID could be used as the userId document ID
in the users collection. This would allow the authenticated user to be
connected to their Firestore user document.

Relationships Between Collections

The three Firestore collections would be connected using IDs.

users
  │
  │ createdBy
  ▼
surveys
  │
  │ surveyId
  ▼
responses

For example:

A user creates a survey.
The survey stores the user's ID in createdBy.
A respondent submits a response.
The response stores the survey's ID in surveyId.
The application can use these IDs to retrieve the appropriate data.
Example Firestore Structure

The overall Firestore structure could look like this:

Firestore
│
├── users
│   └── user123
│       ├── name
│       ├── email
│       ├── createdAt
│       └── surveyIds
│
├── surveys
│   └── survey456
│       ├── title
│       ├── description
│       ├── isPublished
│       ├── allowAnonymousResponses
│       ├── requireRespondentName
│       ├── requireRespondentEmail
│       ├── createdBy
│       ├── createdAt
│       ├── updatedAt
│       └── questions
│
└── responses
    └── response789
        ├── surveyId
        ├── respondentId
        ├── respondentName
        ├── respondentEmail
        ├── submittedAt
        └── answers
Planned Database Operations
Creating a Survey

When a creator saves a survey:

Create a document in the surveys collection.
Store the creator's user ID in createdBy.
Store the survey title and description.
Store the survey questions.
Store the survey settings.
Store the creation and modification timestamps.
Saving a Draft

When a creator saves a survey as a draft:

Create or update the survey document.
Set isPublished to false.
Store the current survey information and questions.
Store the updatedAt timestamp.

The creator can later retrieve the draft and continue editing it.

Editing a Survey

When a creator edits a saved survey:

Locate the survey using its survey ID.
Verify that the authenticated user owns the survey.
Update the survey fields.
Update the questions if necessary.
Update the updatedAt timestamp.
Publishing a Survey

When a creator publishes a survey:

Locate the survey using its survey ID.
Verify that the authenticated user owns the survey.
Set isPublished to true.
Save the updated survey.
Use the survey ID to create the shareable survey URL.

Example:

https://quicksurveys.app/survey/survey456
Submitting a Response

When a respondent submits a survey:

Locate the survey using the survey ID.
Verify that the survey is published.
Create a new document in the responses collection.
Store the associated surveyId.
Store respondent information according to the survey settings.
Store the submitted answers.
Store the submission timestamp.
Viewing Responses

When a survey creator wants to view responses:

Identify the survey ID.
Find response documents where surveyId matches the survey.
Retrieve the answers from each response.
Display the responses to the survey creator.
Survey Settings and Responses

The survey settings determine which respondent information should be stored.

Anonymous Responses

If allowAnonymousResponses is true, the respondent should not be required
to provide identifying information.

Required Respondent Name

If requireRespondentName is true, the respondent must provide their name
before submitting the survey.

Required Respondent Email

If requireRespondentEmail is true, the respondent must provide their email
before submitting the survey.

The application would use these settings when displaying the survey and
processing responses.

Security Considerations

Firestore Security Rules would be used to control access to the data.

Survey creators should only be allowed to create and edit surveys associated
with their own user ID.

Respondents should be able to submit responses to published surveys without
being given permission to modify the survey itself.

Users should not be able to access private survey information belonging to
other users unless the application specifically allows it.

Passwords would not be stored in Firestore. Firebase Authentication would
handle authentication credentials.

Summary

The planned Firestore database would contain three main collections:

Collection	Main Responsibility
users	Stores information about survey creators
surveys	Stores survey information, settings, and questions
responses	Stores submitted survey responses

Firebase Authentication would handle authentication and passwords separately
from Firestore.

The collections would be connected using IDs such as createdBy and
surveyId.

This structure would allow QuickSurveys to:

Create and save surveys
Save survey drafts
Edit existing surveys
Publish surveys
Generate shareable survey URLs
Collect responses
Associate responses with the correct survey
Associate surveys with their creators
Keep authentication credentials separate from application data

**I'd use this version for the project.** It gives you a clear plan without making it sound like you've already implemented Firestore. It also lines up with the functionality you've already built in QuickSurveys.