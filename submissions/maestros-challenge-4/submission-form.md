# AI-HDL Challenge 4 Submission Form

## Basic Information
- **Submission Date**: 2026-05-07
- **Challenge Number**: 4
- **Team Name**: Maestros
- **Team ID**: [Assigned during registration]

## Team Members
| Name | Role | Email | Contribution % |
|------|------|-------|----------------|
| Candice Liu | Team Lead | [candiceliu@arizona.edu] | 33.3% |
| Daniel Onesimo Dong | Team Member | [onesimod@arizona.edu] | 33.3% |
| April Morales | Team Member | [aprilmorales@arizona.edu] | 33.3% |

## Design Specifications Met
- [X] All required functionality implemented
- [X] FPGA implementation successful
- [X] Timing requirements met
- [X] Resource constraints satisfied
- [X] All test cases pass

## AI Tool Usage Declaration
- **Primary AI Tool**: ChatGPT-4, Claude, Gemini
- **Total Conversation Sessions**: 5+
- **Estimated AI-Generated Code %**: 100%
- **Manual Modifications Made**: N/A

## Special Considerations
- **Bonus Features Implemented**: none since design 3
- **Known Issues**: 16 max fanout violations needing RTL changes to fix
- **Future Improvements**: To limit the max fanout errors, we could have staged the reset fanning out to all flip-flops explicitly in RTL, selecting a larger die area to give the placer more breathing room, guiding CTS configuration, and setting a more timing-aggressive synthesis strategy from the start.

## Verification Checklist
- [X] All source files compile without errors
- [X] Testbenches run successfully
- [X] FPGA implementation verified on hardware
- [X] AI interaction logs are complete
- [X] Documentation is thorough and clear

## Team Statement
We certify that this submission represents our original work, completed according to AI-HDL rules and academic integrity guidelines. All AI interactions have been logged and submitted.

**Team Representative**: Maestros
**Date**: 2026-05-07