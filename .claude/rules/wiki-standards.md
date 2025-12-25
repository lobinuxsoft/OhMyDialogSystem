# Wiki Standards

## Location
All wiki files are in `docs/` directory (GitHub Pages).

## Visual Elements
- **ALWAYS** use HTML + CSS for diagrams, flowcharts, and visual elements
- **NEVER** use ASCII art, markdown tables for visuals, or external image dependencies
- Use the existing `styles.css` variables and classes
- Create inline `<style>` blocks for page-specific styles

## CSS Guidelines
- Use CSS Grid/Flexbox for layouts
- Follow the neural/AI color palette from `styles.css`
- Add hover effects and transitions for interactivity
- Ensure responsive design with media queries

## Node Colors (from dialogue-nodes.html)
```css
--node-start: #10b981;    /* Green */
--node-end: #ef4444;      /* Red */
--node-ai: #3b82f6;       /* Blue */
--node-static: #6b7280;   /* Gray */
--node-choice: #eab308;   /* Yellow */
--node-condition: #f97316; /* Orange */
--node-event: #a855f7;    /* Purple */
--node-variable: #06b6d4; /* Cyan */
```

## Structure
- Use semantic HTML5 elements
- Include breadcrumbs navigation
- Update sidebar nav when adding new pages
- Add page to index if it's a new section

## Language
- Page content: Spanish
- Code comments: English
- CSS class names: English (kebab-case)
