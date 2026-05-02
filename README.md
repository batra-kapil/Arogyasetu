# Aarogyasetu — Digital Front Door for Onco Global

**Salesforce Agentforce Hackathon 2026**

---

## The Problem

Onco Global is a cancer care network operating 10+ hospitals across India, managing 500,000 registered patients. Their 7-person contact centre handles 450 calls every day — covering appointment booking, cancellations, specialty queries, and general information. This leaves patients on hold for tasks that could be handled without any human involvement, and leaves contact centre staff with no bandwidth for cases that genuinely need them.

---

## The Solution

Aarogyasetu is a patient-facing scheduling agent built on Salesforce Agentforce, available 24 hours a day on web chat and WhatsApp. It handles the complete appointment lifecycle — from new patient registration through to booking confirmation, 24-hour reminders, and cancellations — without any human involvement for routine cases.

---

## Features and Functionality

### New Patient Registration with OTP Verification
When a patient visits for the first time via web chat, the agent collects their mobile number and sends a one-time password via SMS for verification. Once verified, it collects name, age, and gender and creates a Person Account in Health Cloud in real time. Doctors are also stored as Person Accounts, distinguished from patients via the `SourceSystemIdentifier` field prefix (PAT-XXXX).

### Returning Patient Recognition via Data Cloud
For patients on WhatsApp, the agent matches their incoming phone number against a unified patient profile in Data Cloud. The unified profile is built by linking the Health Cloud Account record with the WhatsApp MessagingEndUser record through an identity resolution ruleset configured on phone number matching. The agent greets returning patients by name without asking them to log in or identify themselves.

### Symptom-to-Specialty Triage via RAG
The agent uses a RAG-grounded knowledge base uploaded to Agentforce as a grounding document. When a patient describes a symptom in plain language, the agent retrieves the relevant section from the knowledge base and maps the symptom to the correct oncology specialty. No code or lookup table is used for this routing — it is handled entirely through the agent's topic instructions and grounded retrieval. Specialties covered: Medical Oncology, Surgical Oncology, Gynaecological Oncology, Paediatric Oncology, Radiation Oncology.

### Doctor and Slot Discovery from Health Cloud
The agent queries `HealthcarePractitionerFacility` and `CareProviderFacilitySpecialty` to find doctors at the patient's nearest centre who match the required specialty. Available slots are calculated by reading the doctor's `OperatingHours` and `TimeSlot` records, then subtracting existing `ServiceAppointment` records to prevent double booking.

### Appointment Booking
On patient confirmation, the agent creates a `ServiceAppointment` record in Health Cloud with the following fields: `AccountId` (patient), `Doctor__c` (custom Lookup to HealthcareProvider), `WorkTypeId` (specialty and duration), `Practitioner_Facility_ID__c` (custom Text field storing the HealthcarePractitionerFacility ID), `SchedStartTime`, `SchedEndTime`, and `Status`.

### SMS Confirmation
An SMS confirmation is sent immediately after booking using an Apex Invocable Action (`TwilioSMSAction`) that calls an external SMS gateway via a Named Credential. Credentials are stored securely using a Named Credential with an External Credential and a custom Authorization header formula — no credentials appear in code.

### 24-Hour Appointment Reminder
A Scheduled Flow fires 24 hours before every `ServiceAppointment` record's `SchedStartTime`. It queries upcoming appointments, retrieves the patient's phone number from the linked Account, and sends a personalised SMS reminder with the doctor's name, appointment time, and centre. This directly addresses the no-show rate without any manual intervention.

### Cancellation via WhatsApp
Patients can cancel in the same WhatsApp conversation thread. The agent confirms the appointment details, cancels on the patient's confirmation, updates `ServiceAppointment.Status` to `Canceled`, and releases the slot for the next patient — all in three messages.

### Escalation to Human Agents
The agent escalates to a human in specific situations: patient distress or crisis, medical emergencies, complaints about previous appointments, requests for clinical opinions or test result interpretation, and complex multi-specialty scheduling. Escalations pass the full conversation summary and patient details so the patient does not have to repeat themselves.

---

## Salesforce Objects Used

| Object | Usage |
|---|---|
| `Account` (Person Account) | Stores both patient and doctor records. Patients identified by `SourceSystemIdentifier` prefix PAT-XXXX. |
| `HealthcareProvider` | Doctor's professional record, linked to their Person Account |
| `HealthcareFacility` | Hospital/centre records, linked to Location and Address objects |
| `HealthcarePractitionerFacility` | Junction linking a doctor to a hospital with their operating hours |
| `CareSpecialty` | Oncology specialty records |
| `CareProviderFacilitySpecialty` | Junction linking a doctor's specialty to a facility |
| `OperatingHours` | Doctor's working schedule |
| `TimeSlot` | Individual time blocks within a doctor's operating hours |
| `WorkType` | Consultation type and duration per specialty |
| `ServiceAppointment` | Appointment records with two custom fields: `Doctor__c` and `Practitioner_Facility_ID__c` |
| `OTP_Verification__c` | Custom object storing OTP code, phone number, expiry time, and verification status |
| `MessagingEndUser` | WhatsApp user records, ingested into Data Cloud for identity resolution |

---

## Products, Features, Tools, and APIs Used

| Product / Tool | How It Is Used |
|---|---|
| **Salesforce Agentforce** | Patient-facing autonomous agent — handles natural language, intent detection, specialty routing, action dispatch |
| **Salesforce Health Cloud** | Full provider and patient data model — HealthcareProvider, HealthcareFacility, HealthcarePractitionerFacility, CareSpecialty, OperatingHours, ServiceAppointment |
| **Salesforce Data Cloud** | Unified patient identity — data streams from Account and MessagingEndUser, identity resolution by phone number, unified individual profiles |
| **Agentforce RAG / Einstein Search** | Knowledge base grounding — symptom-to-specialty routing, doctor profiles, hospital information, FAQs, escalation guide |
| **Salesforce Flow (Record-Triggered)** | Creates ServiceAppointment on booking confirmation |
| **Salesforce Flow (Scheduled)** | Fires 24 hours before each appointment to send SMS reminder |
| **Apex Invocable Actions** | `TwilioSMSAction` — sends SMS via external gateway. `GetAvailableSlots` — calculates available time slots from OperatingHours minus booked appointments |
| **Named Credentials + External Credentials** | Secure callout to SMS gateway — Auth Token stored encrypted, never in code |
| **Salesforce Digital Engagement** | WhatsApp channel for patient conversations |
| **Custom Labels** | Non-sensitive configuration values (Account SID, From number) |
| **SFDX / Salesforce CLI** | Source control and metadata management |

---

## Data Cloud Configuration

- **Data Stream 1**: Salesforce CRM → Account (filtered to Person Accounts with SourceSystemIdentifier LIKE 'PAT-%'), mapped to Individual DMO
- **Data Stream 2**: Salesforce CRM → MessagingEndUser, mapped to ContactPointPhone DMO
- **Identity Resolution Ruleset**: Phone number exact match across both streams
- **Unified Individual**: Single merged profile per patient, queryable by incoming WhatsApp phone number

---

## Setup Instructions

### Prerequisites
- Salesforce org with Health Cloud and Data Cloud enabled
- Agentforce enabled in the org
- Salesforce CLI installed and authenticated

### Retrieve Metadata
```bash
sf project retrieve start --manifest manifest/package.xml -o <your-org-alias>
```

### Named Credential Setup
Create an External Credential named `Twilio_External_Credential` with:
- Authentication Protocol: Custom
- Principal: `TwilioNamedPrincipal`
- Parameters: `Username` (Account SID), `Password` (Auth Token)
- Custom Header: `Authorization` with Base64 encoded Basic auth formula

Create a Named Credential named `Twilio_API` linked to the External Credential above.

### Data Cloud Setup
Import the Datakit from `data-cloud/datakits/` and run the identity resolution ruleset. Verify unified profiles exist in Data Cloud → Data Explorer → Unified Individual object.

### RAG Knowledge Base
Upload `docs/OncoGlobal_Knowledge_Base.pdf` to Agentforce Knowledge and link it as a data source on the Agentforce agent.

---

## Potential Further Improvements

- **Native WhatsApp Business API integration** — replace the sandbox setup with a verified WhatsApp Business Account and approved message templates for outbound confirmations
- **Multi-language agent support** — add regional language detection so patients can interact in their preferred language
- **Payment integration** — collect advance consultation fees during booking to reduce no-shows further
- **Patient portal app** — extend the agent to a full self-service portal where patients can view their appointment history, download reports, and manage their profile
- **Proactive outreach** — use Data Cloud segmentation to identify patients who have not had a follow-up in over 6 months and trigger outbound WhatsApp messages

---

## Team

**Team AUTOMATES ASSEMBLE**

| Name | Role |
|---|---|
| Jyothsna Bitra | Architect, Arxcient |
| Kapil Batra (Team Captain) | Product Owner, Teradata |
| Monika Ramchandani | Lead Developer, Icreon |

---

*Salesforce Agentforce Hackathon 2026 — Onco Global Digital Front Door*
