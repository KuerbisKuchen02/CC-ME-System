---
title: CCME-System Architecture documentation
---

# 0. Preface

## 0.1 Terminology and Conformance Language

Normative text describes one or both of the following kinds of elements:

Vital elements of the specification
Elements that contain the conformance language key words as defined by IETF RFC 2119 "Key words for use in RFCs to Indicate Requirement Levels"
Informative text is potentially helpful to the user, but dispensable.
Informative text can be changed, added, or deleted editorially without negatively affecting the implementation of the specification.
Informative text does not contain conformance keywords.

All text in this document is, by default, normative.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in IETF RFC 2119 "Key words for use in RFCs to Indicate Requirement Levels".

According to: <https://datatracker.ietf.org/doc/rfc2119/>

## 0.2 Structure of the documentation

This architecture documentation is based on the arc42 template for documenting software architectures.
The template provides a structured and proven approach for describing technical architectures and is widely and successfully used in practice.
The goal is to document all relevant aspects of the architecture of our Android app in such a way that development, maintenance, and further evolution can be carried out efficiently and transparently.

The following provides an overview of the individual chapters:

1. **Introduction and Goals** – Description of the fundamental goals, stakeholders, and constraints of the software.
2. **Constraints** – Technical, organizational, and legal constraints.
3. **Context Boundary** – Depiction of the system in the context of its environment (neighboring systems, users, external interfaces).
4. **Solution Strategy** – Description of the fundamental architectural decisions.
5. **Building Block View** – Decomposition of the system into functional building blocks with descriptions of their responsibilities.
6. **Runtime View** – Description of the system’s dynamic aspects (e.g., key processes, interactions).
7. **Deployment View** – Representation of the distribution of software components across hardware/networks.
8. **Cross-cutting Concepts** – Description of technical and domain-specific concepts that affect multiple components.
9. **Decisions** – Documentation of significant architectural decisions, including alternatives and rationale.
10. **Quality Requirements** – Definition and evaluation of the most important quality goals.
11. **Risks and Technical Debt** – Listing of identified risks and technical debts.
12. **Glossary** – Explanation of important terms.
13. **Appendix** – Additional information, sources, references.

# 1. Introuction and Goals

This chapter describes the key requirements and driving forces (stakeholders) that must be taken into account during the development process of the "CCME-System".

## 1.1 Motivation

The CCME-System is an automatic stoarge solution inspried by the matter energy system from the [Applied Energistics 2 Mod](https://github.com/AppliedEnergistics/Applied-Energistics-2).
It aims to deliver an intuitive, flexible, and automated solution for item storage, crafting and retrival.
The motivation behind the Project is to reduce the manual effort required to manage large quantities of items from various mods across diverent storage containers.
By integrating advanced filtering, searching, and autocrafting functionalities, the CCME-System enhances the overall efficiency and enjoyment of gameplay, allowing the player to focus more on building and exploration rather than on tedious inventory management tasks.

## 1.2 Stakeholder

| Name          | Role            | Description                                                                                                      |
|---------------|-----------------|------------------------------------------------------------------------------------------------------------------|
| KuerbisKuchen | Developer, User | The system should be user-friendly and integrate seamlessly into existing mod workflows with minimal disruption. |

## 1.3 Requirements

**Requirement-type:**

| Short | Meaning  | Description                                                                                           |
|-------|----------|-------------------------------------------------------------------------------------------------------|
| `M`   | Must     | Must be fulfilled, otherwise the architecture is not acceptable                                       |
| `O`   | Optional | Optional, but desirable, requirements that can be fulfilled later                                     |
| `Q`   | Quality  | Quality requirements that are not directly related to the architecture, but to the system as a whole  |

`<type>`-`<id>` e.g. `M-1`, `O-1`, `Q-1`

### 1.4.1 Non-functional Requirements / Quality Goals

**Quality goals as defined by [ISO 25010](https://www.iso.org/obp/ui/#iso:std:iso-iec:25010:ed-2:v1:en):**

| Quality goal           | Description                                                                                                                                                                                                                                |
|------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Functional suitability | Capability of a product to provide functions that meet stated and implied needs of intended users when it is used under specified conditions                                                                                               |
| Performance efficiency | Capability of a product to perform its functions within specified time and throughput parameters and be efficient in the use of resources under specified conditions                                                                       |  
| Compatibility          | Capability of a product to exchange information with other products, and/or to perform its required functions while sharing the same common environment and resources                                                                      |
| Interaction capability | Capability of a product to be interacted with by specified users to exchange information between a user and a system via the user interface to complete the intended task                                                                  |
| Reliability            | Capability of a product to perform specified functions under specified conditions for a specified period of time without interruptions and failures                                                                                        |
| Security               | Capability of a product to protect information and data so that persons or other products have the degree of data access appropriate to their types and levels of authorization, and to defend against attack patterns by malicious actors |
| Maintainability        | Capability of a product to be modified by the intended maintainers with effectiveness and efficiency                                                                                                                                       |
| Flexibility            | Capability of a product to be adapted to changes in its requirements, contexts of use, or system environment                                                                                                                               |
| Safety                 | Capability of a product under defined conditions to avoid a state in which human life, health, property, or the environment is endangered                                                                                                  |

**Priorities:**

| Prio | Description         | Explanation                                                          |
|------|---------------------|----------------------------------------------------------------------|
| 1    | Extremely important | Compromises only when higher priority features are strengthened.     |
| 2    | Important           | Compromises are possible when core requirements are not compromised. |
| 3    | Significant         | Compromises are possible when core requirements are not compromised. |
| 4    | Insignificant       | This feature should only be taken into account to a limited extent.  |

| ID  | Prio | Quality Goal           | Description                                   |
|-----|------|------------------------|-----------------------------------------------|
| Q-1 |      | -                      | -                                             |

### 1.4.2 Functional Requirements

| ID  | Description                                                                          |
| --- | ------------------------------------------------------------------------------------ |
| M-1 | The system MUST support the generic `inventory` interface for storage containers.    |
| M-2 | The system MUST support the generic `item_storage` interface for storage containers. |
| M-3 | The system MUST support hot-swap for storage containers                              |
| M-4 | The system MUST support hot-swap for (wireless) modems                               |
| M-5 | The system MUST support pull and push operations form external storage containers    |
| M-6 | -                                                                                    |

# 2. Constraints

In this chapter, the organizational and technical framework conditions as well as binding conventions that influence or constrain the design and development process are described.

## 2.1 Organizational Constraints

\-

## 2.2 Technical Constraints

| Constraint                 | Explanation                                                                        |
| -------------------------- | ---------------------------------------------------------------------------------- |
| Technology                 | Lua                                                                                |
| Runtime environment        | Minecraft 1.18.2<br>Create: Astral v2.0.5b<br>CC: Restitched v1.100.8              |
| Server Hardware            | Basic Computer with wireless modem                                                 |
| Client Hardware            | Basic Computer                                                                     |
| Remote Client Hardware     | Basic Computer with wireless modem or<br>Basic Pocket Computer with wireless modem |
| Inventories                | Support all inventories that implement the inventory api                           |
| Processing Worker (Turtle) | Basic Turtle with wireless modem                                                   |
| Crafting Worker (Turtle)   | Basic Turtle with wireless modem and crafting                                      |

## 2.3 Conventions

Programming conventions can be found here: [Conventions](/doc/conventions.md)

# 3. Context Boundary

The context delimitation presents the "CCME-System" in relation to its external interfaces, users, and neighboring systems.
The aim of this chapter is to make the system's communication relationships with its environment transparent.

# 3.1 Business Context

# 3.2 Technical Context

![Technical context diagram](/doc/diagrams/ccmesystem_system_context.svg)

# 4. Server Architecture

# 4.1 Solution Strategy

# 4.2 Building Block View

![Server Component View](/doc/diagrams/server_component_view.svg)

# 4.3 Runtime View

<!------------------------------------------->

# 5. Client Architecture

# 5.1 Solution Strategy

# 5.2 Building Block View

# 5.3 Runtime View

<!------------------------------------------->

# 6. Turtle Architecture

# 6.1 Solution Strategy

# 6.2 Building Block View

# 6.3 Runtime View

# 7. Deployment View

# 8. Cross-cutting Concepts

- ErrorManager
- Logging
- Plugins
- Classes
- Properties
- Config

# 9. Decisions

# 10. Quality Requirements

# 11. Risks and Technical Debt

# 12. Glossary

# 13. Appendix
