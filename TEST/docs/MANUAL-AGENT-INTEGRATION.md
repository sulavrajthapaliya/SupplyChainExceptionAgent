# Manual Agent Integration Checks

The automated suite intentionally does not create or activate a real Microsoft Agent user. After the deterministic tests pass, validate the live Agent flow manually in the same SaaS sandbox:

1. Open **Supply Chain Exception Setup** and configure the agent.
2. Activate the Supply Chain Exception Agent.
3. Create a sales order that produces a deterministic shortage exception.
4. Run the full scan and confirm an analysis is created.
5. Run **Run Scan and Send to Agent**.
6. Confirm an Agent Task is created and the `Agent Task ID` is stored on the analysis header.
7. Confirm the agent summarizes the deterministic values rather than inventing quantities or dates.
8. Confirm the agent does not create, release, modify, post, ship, or receive any Business Central document.
9. Disable the agent and confirm task creation returns the app-level unavailable/inactive message.
10. Re-enable it and confirm task creation succeeds again.

These checks depend on tenant Copilot/Agent feature state and therefore are intentionally outside the deterministic automated suite.
