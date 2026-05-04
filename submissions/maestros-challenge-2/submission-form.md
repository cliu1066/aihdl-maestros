# AI-HDL Challenge 2 Submission Form

## Basic Information
- **Submission Date**: [2026-05-04] 
- **Challenge Number**: 2
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
- **Estimated AI-Generated Code %**: [95%]
- **Manual Modifications Made**: 
    Most of the mannual modifications were small motifications with naming, formatting and minor details that AI did not generate. For the most part AI generated most of the functional code based off the prompts and designs given. 

## Special Considerations
- **Bonus Features Implemented**:
    - Synchronizer Module: Instead of hardcoding two FF synchronizer chains inline, we utilize a reusable/portable synchronizer module.
    - Standalone SPI Register Interface: SPI to register bridge is its own module so traffic light logic can be tested independently while SPI path can be exercised separately through the wrapper.
- **Known Issues**: N/A
- **Future Improvements**: Implement a real SPI master FSM so the ESP32 WiFi count is fetched autonomously by the peripheral itself, using other sources of WiFi.

## Verification Checklist
- [X] All source files compile without errors
- [X] Testbenches run successfully
- [x] FPGA implementation verified on hardware
- [X] AI interaction logs are complete
- [X] Documentation is thorough and clear

## Team Statement
We certify that this submission represents our original work, completed according to AI-HDL rules and academic integrity guidelines. All AI interactions have been logged and submitted.

**Team Representative**: Maestros
**Date**: [2026-05-04] 