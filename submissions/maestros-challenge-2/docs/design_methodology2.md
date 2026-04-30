# Design Methodology

## Initial Approach
How did you start? What was your overall strategy?

The implementation for the optimization was started by simply prompting AI in order to find out what exactly we could optimize. We also took into consideration what the suggested optimizations that we could implement and narrowed down what would be most reasonable for us to use.

## AI Integration Strategy
How did you plan to use AI tools? What was your prompting strategy?

We planned on using multiple AI programs to write the code and verify the code so we don't have one system agreeing with itself. Our promting strategy was to make sure that the prompts were not too heavy on how many tasks we were asking AI to do. Then if we wanted to have more specific information, or to validate that the code functionaliy would work, we asked AI to validate what they had just given us to what our expected result wanted to be.

## Design Evolution
How did your design change throughout the process?

Our design changed mostly in order to include the external device we are intending it to be used with. Instead of allowing a large amount of people to be counted, we brought that number down in order to only detect around 15 different signals. Since this design was originally thought of for those instances when there is no heavy traffic and a person is stuck at a light with no oncomming traffic, we felt this number was still valid for the design. 

## Key Decisions
What were the major design decisions and trade-offs?

Some trade offs were the idea that we still had to make this peripheral viable for when we do have a lot of oncomming traffic. In these instances, since we already know that the original old style system for traffic lights were sufficent, we defaulted the system to go there for when there was an overflow. 

## Verification Strategy
How did you ensure your design was correct?

We ran the code on verilog and inquired with AI on the validity of our results. Additionally we made sure that the design did not change any of our original fundamental functionality. 