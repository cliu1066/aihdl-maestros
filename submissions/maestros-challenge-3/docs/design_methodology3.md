# Design Methodology

## Initial Approach
How did you start? What was your overall strategy?

The implementation for the security feature optimization was started by simply prompting AI in order to find out what exactly we could optimize or implement in terms of security. We prompted different LLMs and then asked AI to reconcile the different ideas. We took these prompts and kept prompting until we had a finalized solution for the security feature and then we asked the AI to generate it. 

## AI Integration Strategy
How did you plan to use AI tools? What was your prompting strategy?

We planned on using multiple AI programs to write the code and verify the code so we don't have one system agreeing with itself. Our prompting strategy was to make sure that the prompts were not too heavy on how many tasks we were asking AI to do. Then if we wanted to have more specific information, or to validate that the code functionality would work, we asked AI to validate what they had just given us to what our expected result wanted to be. However, since some of our members know more about security features, we had them run the initial code prompts and generations and had a secondary AI system check the work. 

## Design Evolution
How did your design change throughout the process?

Our design changed mostly in order to include what we had anticipated in the first place, just this time we actually included the implementation of the actual ESP32 device. We kept the lowered amount of people to be counted and we also included some authentication features that would be used with the ESP32 device. We also did not anticipate having to refresh our authentication procedures or that those procedures would be too large for the tinyTapeOut. Since this design iteration was mainly focused on security, we took as many feasible steps we could in order to achieve maximum security. 

## Key Decisions
What were the major design decisions and trade-offs?

One of the biggest design decisions for this submission was the choice to use ESP32's authentication features in order to help us achieve better security features and then validate that message on our side so that we did not do any major computations on chip. Another decision was to slow the clock rate for refreshing that authentication. Although it will open ourselves to timing attacks, it also allows our system to reduce power. Since this device monitorization is not anticipated to be on for extended periods of time, we felt the lowered authentication refresh rate was acceptable. 

## Verification Strategy
How did you ensure your design was correct?

We ran the code on verilog and inquired with AI on the validity of our results. Additionally we made sure that the design did not change any of our original fundamental functionality.
