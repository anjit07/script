# Overview

## UM AI Assistant Chatbot

### Problem Statement

Users often face challenges while using the application due to limited domain knowledge or lack of familiarity with specific functionalities. As a result, they are unable to take appropriate actions or frequently raise duplicate issues. An AI-powered assistant can help users understand the application, provide guidance, and reduce duplicate incident creation.

### Use Case 1: Functional Guidance

Some users have limited domain knowledge and are unable to understand why certain actions or data are unavailable in the application.

**Example:**
A user cannot see expected values in a form dropdown because of role-based restrictions. The AI assistant can explain why the values are not populated and guide the user on the required permissions or conditions.

### Use Case 2: Trending Issues Awareness

When users open the chatbot, they will be presented with the top five trending issues currently reported in ServiceNow.

* The list of issues will be fetched from ServiceNow.
* Similar issues will be grouped and summarized into business-friendly descriptions.
* Users experiencing the same problem can identify existing issues and avoid creating duplicate reports.

### Use Case 3: Issue Assistance and Duplicate Prevention

When a user opens the chatbot to report an issue:

* The top five trending issues will be displayed in the chatbot header.
* The user can describe the problem in natural language.
* The AI agent will analyze the user's request and determine whether:

  * the issue can be resolved using the knowledge base, or
  * a similar issue has already been reported.
* If a matching issue exists, the assistant will provide details in business-friendly language.
* This helps users avoid creating duplicate incidents.

### Use Case 4: Automated Incident Creation

If the issue is not already known and requires reporting:

* The AI agent will analyze the entire conversation history from the beginning of the chat session.
* Based on the conversation, the agent will generate a concise summary of the issue.
* The summary will be presented to the user for review.
* Users can modify or add additional details if necessary.
* Once confirmed, the system will create an incident in ServiceNow using the generated summary.

# Solution

The solution consists of a single LLM agent powered by **Claude 3.5 Sonnet** with four callable tools.

### Tool 1: Knowledge Base Retrieval

* Retrieve information from the knowledge base.
* Provide guidance and answers to user questions.
* Assist users in understanding application functionality.

### Tool 2: Trending Issue Generation

* Fetch issues from ServiceNow.
* Identify and aggregate similar incidents.
* Generate the top five trending issues in business-friendly language.
* Store and retrieve trending issue information for display.

### Tool 3: Existing Incident Lookup

* Retrieve all open and in-progress incidents from ServiceNow.
* Compare the user's problem with existing issues.
* Inform the user when a similar issue has already been reported and provide relevant details.

### Tool 4: Incident Summary Generation

* Analyze the complete chat conversation.
* Generate a structured issue summary.
* Present the summary to the user for review and modification.
* Create a ServiceNow incident after user confirmation.

### Agent Orchestration

The AI agent determines which tool to invoke based on the user's request and the conversation context. This enables intelligent assistance, reduces duplicate incident creation, and improves the overall user experience.
