# AI Strategy and Usage

## Tool Selection
Why did you choose specific AI tools?

We chose to use multiple AI tools, including ChatGPT-4, Claude, and Gemini, because each tool was useful for a different part of the design process. The team was already familiar with these tools, so we were able to build on our existing experience while also learning how each tool responded differently to hardware-design prompts. Using more than one AI tool also helped us avoid relying on one system to both generate and verify the same design decisions.

## Prompting Techniques
What prompting strategies worked best?

The most effective prompts were specific, goal-oriented, and limited in scope. We found that prompts worked best when they included the end goal of the design, the exact hardware context, the TinyQV/RISC-V peripheral structure, and the constraints of the project. For example, prompts that explained that the design was for a TinyQV peripheral connected to an ESP32 over SPI produced better results than general prompts asking for a traffic-light controller.

We also learned that smaller prompts produced fewer mistakes. Instead of asking AI to generate the entire final design at once, we broke the work into smaller tasks. These tasks included SPI input handling, register mapping, synchronizer design, WiFi count storage, threshold comparison, loop-detector priority, interrupt behavior, PPA optimization, packet authentication, sequence-number checking, lockout behavior, and stale-data timeout. This made the generated code easier to inspect and reduced the chance that the AI would ignore important constraints.

Another useful technique was asking AI to review or challenge its own previous output. After receiving a design suggestion, we often asked whether the design actually matched our expected behavior, whether it would synthesize cleanly, whether it created unnecessary area, or whether it introduced a security weakness. This helped us catch cases where the generated design worked in a general sense but did not match our exact intended architecture.

We also referenced previous chat results and design versions to compare approaches. This was useful because some earlier results were better for PPA, while later results were better for security. Comparing multiple versions helped us understand why DP2 had better area but DP3 had better security and final timing. This process made it easier to choose the final DP3/DP4 security-hardened version for submission. 

## Iteration Process
How did you refine AI-generated code?

Our iteration process started with AI-generated ideas, but the final design was not accepted without review. After receiving generated RTL or design suggestions, we compared the response against the project requirements, the TinyQV template, our own understanding from coursework, and previous versions of the design. We checked whether the generated code preserved the original purpose of the project: using the ESP32 as a supplemental WiFi-count sensor while keeping the inductive-loop detector as the priority path.

When a generated version did not match our intended architecture, we refined the prompt and asked for a more constrained revision. For example, some versions assumed that the WiFi count was already available internally rather than being received through true SPI. Other versions tried to implement too much traffic-light timing directly on the chip, even though the intended design was to let the legacy controller or 555-timer-style circuit handle the actual light timing. Through iteration, we corrected the design so TinyQV only authenticates the ESP32 data, evaluates demand, and asserts a supplemental request.

We also used iteration to refine the security approach. At first, the team considered stronger authentication options, but those were too expensive for the size of the target peripheral. AI helped compare stronger cryptographic approaches with lightweight alternatives. The final design uses keyed CRC8 authentication, sequence-number replay checking, stale-data timeout, and brute-force lockout because these features offered a practical middle ground between no security and an overly large cryptographic block.

The PPA iteration process was also important. DP2 showed that the design could be made much smaller by simplifying logic and reducing unnecessary registers. However, the smallest version did not include the final security features. DP3 increased area but added authentication, replay protection, timeout logic, lockout behavior, and status reporting while still achieving strong timing. By comparing each iteration, we learned that the final design should be judged by overall engineering tradeoff rather than by area alone.

## AI Limitations Encountered
Where did AI fall short? How did you overcome limitations?

One major limitation was that AI performed worse when the prompt included too many goals at once. When we asked for functionality, security, PPA optimization, TinyQV compatibility, SPI behavior, and testbench generation all in the same prompt, the output was more likely to miss details or combine ideas incorrectly. We overcame this by breaking the problem into smaller prompts and giving direct constraints about what the code was allowed to change.

Another limitation was that AI sometimes held onto earlier design assumptions even after we changed the architecture. For example, after earlier versions included internal timing behavior or simplified WiFi count assumptions, AI sometimes continued generating code based on those older ideas. We had to explicitly restate that the ESP32 should act only as a sensor, that true SPI input was required, and that the legacy traffic-light controller should handle the actual timing.

AI also sometimes suggested security features that were conceptually good but unrealistic for the project constraints. Strong cryptographic authentication, encryption, larger logs, and more advanced security monitors would improve security, but they would also increase area and complexity. We overcame this by asking AI to evaluate tradeoffs and by choosing features that were practical for a TinyQV-style peripheral.

Another limitation was that AI-generated code still required manual review. Even when the syntax looked correct, we needed to check whether the design matched the intended register behavior, interrupt behavior, SPI packet format, and trust boundary. We also needed to confirm that the testbench covered both valid and invalid cases. This showed us that AI is a useful design assistant, but it does not replace engineering judgment or verification.

## Learning from AI
What did AI teach you about hardware design?

AI helped reinforce several hardware-design concepts that we had learned in class. Through the design process, we saw repeated examples of synchronization, clock-domain safety, register mapping, finite-state behavior, fanout reduction, pipelining, testbench structure, and PPA tradeoffs. Seeing these concepts applied to our own TinyQV peripheral helped connect classroom material to a practical RTL design.

One important lesson from AI was the importance of clear trust boundaries. Before the security-focused iterations, it was easy to think of the ESP32 as simply another part of the system. AI-assisted vulnerability analysis helped us recognize that the ESP32 is an external device and should not have full authority over the peripheral. This led to the final decision that SPI packets can update the WiFi count, but cannot write the control or threshold registers.

AI also helped us understand that security features have direct hardware costs. Adding authentication, sequence checking, lockout counters, status registers, and timeout logic increased area, but also made the design more robust. This helped us understand why security, power, performance, and area must be considered together rather than separately.

Finally, AI taught us the importance of verifying failure cases. At first, it was natural to focus on whether a valid WiFi count caused the correct request output. Later, AI-assisted review showed that the design also needed to reject invalid packets, reject replayed packets, expire stale data, trigger lockout, and preserve inductive-loop priority. This made the final verification strategy stronger and made the final design more defensible.