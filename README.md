Sakhi

1. Problem Statement
What women's challenge are you addressing?
Women lack a single tool that connects their hormonal cycle to their daily schedule, safety, and emotional wellbeing. They manage these things across 4–6 separate apps that don't communicate with each other. A period tracker that doesn't know about tomorrow's presentation, a calendar that doesn't know she's exhausted, an AI assistant that knows nothing about your cycle.
Why is this problem important?
85% of women experience significant cycle-related shifts in energy and cognition that affect their daily performance, yet no mainstream productivity or planning tool accounts for this. Conditions like PCOS and endometriosis take an average of 7–10 years to diagnose due to lack of structured pattern tracking. Personal safety remains a daily, unaddressed concern for women commuting and travelling alone, existing safety apps are reactive, not passive.
Who is affected?
All women with a smartphone and a schedule. Most acutely: working professionals managing performance without cycle awareness, students without visibility into their cognitive peaks, women with irregular or symptomatic cycles, and women without strong support networks navigating daily life alone.

2. Proposed Solution
What is Sakhi?
Sakhi is an Android and iOS mobile app, a women-centric AI personal assistant that combines five features into one connected product: a passive safety shield, a menstrual cycle tracker, a cycle-aware calendar, an AI companion, and a journal.
What makes it innovative?
What makes our solution innovative is that every feature feeds the other. The journal informs the morning check-in by the AI companion. The cycle phase shapes what the pre-task notification says. The calendar history informs what the AI says when you open the app. No existing product connects these layers.

3. Target Users
Who will use your solution?
•	Working women (22–35) navigating performance expectations across a hormonal cycle no workplace acknowledges
•	Students managing study and exams without awareness of cognitive peaks and troughs
•	Women with PCOS, endometriosis, or PMDD who need longitudinal pattern data for medical consultations
•	Women who commute, travel, or date alone and need passive, always-on safety
•	Women without strong support networks who would benefit from consistent, context-aware emotional support
What pain points does it address for them?
•	No awareness of how their cycle affects performance on a given day
•	No way to prepare for a difficult task based on expected energy and cognitive state
•	Safety apps that require action in the moment of danger
•	Journaling tools with no feedback loop: writing that nothing is done with
•	Generic AI assistants with no knowledge of their actual life context
•	Cycle-related relationship friction with no tool to bridge the communication gap

4. Key Features
Feature 1 — Sakhi Shield (safety) A home-screen widget activated as a precaution — before you feel in danger, not during it. One long-press before getting into a cab alone, leaving the office late, or walking through an area that feels off starts Shield mode with no visible change to the screen. A silent check-in timer runs in the background. If the user doesn't tap "I'm safe" within her set time window, the camera and microphone begin recording, footage uploads to AES-256 encrypted cloud storage, and live GPS is shared with up to three emergency contacts in real time. 
Another safety feature is the fake call button that when pressed triggers a convincing full-screen incoming call, letting the user act as if she's on a call to safely exit an uncomfortable situation.

Feature 2 — Cycle-aware calendar Connects to Google Calendar and Apple Calendar. Reads upcoming events and sends a phase-aware briefing 30 minutes before each one — what cognitive state the user is likely in, what to lean into, what to watch for. Flags high-stakes events scheduled during low-energy phases and suggests better windows. Optional partner mode sends educational cycle phase summaries to a connected partner with full user consent and control.
Feature 3 — Sakhi AI companion An AI with a consistent personality powered by the Claude API. Every response is informed by the user's current cycle phase, today's calendar, and last night's journal entry. Checks in each morning with a message that references something specific from the user's life. Available throughout the day for planning, venting, or working through a decision. Random context -based notifications sent through the day, to help the user stay motivated through the day.
Feature 4 — End-of-day journal Triggered each evening with today's task list auto-filled from the calendar. User rates each task 1–5 stars and adds free-form notes. Done in under 90 seconds. Sakhi reads the journal overnight and references it in the next morning's check-in — closing the loop between reflection and daily guidance.
Feature 5 — Resilience Points Tasks earn points weighted by cycle phase — completing a task during the menstrual phase earns double because it is genuinely harder. Journal streaks earn multipliers. Points build toward a monthly Cycle Report Card. The system rewards showing up on hard days, not just productivity on good ones.

5. Technical Approach
Proposed tech stack
Layer	Technology
Frontend	Flutter (Android + iOS)
AI companion	Claude API — Anthropic
Backend	Firebase (Auth, Firestore, Cloud Functions)
Calendar integration	Google Calendar API + Apple EventKit
Notifications	Firebase Cloud Messaging
Safety recording	Flutter camera + mic + background service
Safety storage	Firebase Storage (AES-256 encrypted)
Live location	Google Maps SDK + Geolocator plugin
Fake call UI	Flutter audio + call screen overlay
Cycle prediction	TensorFlow Lite (on-device)
Local storage	Hive (AES-256 encrypted)
State management	Riverpod

Basic system architecture
Three layers:
•	On-device: Cycle prediction, journal and cycle data storage, background recording service, fake call UI. Works offline. No server dependency for core privacy-sensitive functions.
•	Cloud layer: Firebase handles authentication, cross-device sync, calendar polling, notification scheduling, and encrypted safety recording storage.
•	AI layer: Claude API receives a structured context packet — current cycle phase, task titles, and a journal summary. Raw health data and full journal text are never included. All calls are stateless.
APIs and technologies used
Claude API (Anthropic), Google Calendar API, Apple EventKit, Google Maps SDK, Firebase suite, TensorFlow Lite, Flutter.

6. Impact & Scalability
How will your solution improve women's wellbeing?
•	Safety: Passive, always-on protection means evidence is in the cloud before anything happens. The fake call feature gives women a practical, low-confrontation exit from unsafe situations.
•	Physical health: Longitudinal cycle tracking flags patterns linked to PCOS, endometriosis, and thyroid conditions — cutting years off the average diagnosis timeline. Medical export generates a structured report ready for a doctor's appointment.
•	Career performance: Scheduling high-stakes moments around peak communication and cognitive phases creates measurable performance improvement. Research shows cycle-synced work improves output by up to 20%.
•	Mental wellbeing: Consistent, context-aware AI support reduces isolation. The journal habit, backed by a real feedback loop, builds emotional literacy over time.
•	Relationships: The partner education feature reduces the recurring friction of women having to explain their cycle's effects to someone who cares but doesn't understand.
•	Scalability: Sakhi launches free, targeting college campuses, working women in urban India, and women-in-tech communities. The longer-term plan is corporate wellness partnerships — giving companies a practical way to support their female workforce. The codebase is fully open source, so developers worldwide can extend it for different conditions, languages, and use cases. Immediate addressable market is 300 million urban women across India and Southeast Asia, with 2 billion+ globally.

