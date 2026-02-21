---
title: Research state management options for dashboard
status: inbox
created: 2026-02-19T10:15
---

The dashboard app is getting complex enough that prop drilling is painful. Need to evaluate options: React Context, Zustand, Jotai, or just restructure the component tree.

Key criteria:
- Bundle size (dashboard loads on mobile too)
- DevTools support
- Learning curve for the rest of the team
