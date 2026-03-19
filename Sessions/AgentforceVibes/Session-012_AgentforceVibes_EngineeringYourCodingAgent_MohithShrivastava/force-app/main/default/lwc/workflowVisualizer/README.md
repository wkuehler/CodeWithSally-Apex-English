# Workflow Visualizer Lightning Web Component

## Overview

The Workflow Visualizer is a Lightning Web Component that provides an interactive visualization of an AI-assisted development workflow. Based on a hand-drawn workflow diagram, this component displays the sequential steps involved in AI development processes with human oversight and iterative refinement.

## Features

- **Interactive Step Visualization**: Visual representation of 7 workflow steps with status indicators
- **Progress Tracking**: Real-time progress bar showing completion percentage  
- **Step Navigation**: Forward/backward navigation through workflow steps
- **Status Management**: Visual indicators for completed, in-progress, and pending steps
- **Responsive Design**: Optimized for desktop, tablet, and mobile devices
- **Accessibility**: Full keyboard navigation and screen reader support
- **State Management**: Proper loading, error, and empty state handling

## Workflow Steps

The component visualizes the following development workflow:

1. **Human Prompt** - User provides initial requirements and specifications
2. **Plan Spec** - Generate initial planning specifications  
3. **Finalized Spec** - Iterate with human supervision to finalize specifications
4. **Generate TDD** - Generate Test-Driven Development specifications
5. **Validate TDD** - Validate and refine TDD specifications
6. **Generate Code** - Generate code based on validated specifications
7. **Final Code** - Deliver final tested and validated code

## Usage

### Lightning Page Builder
1. Navigate to the Lightning App Builder
2. Edit an existing page or create a new one
3. Drag the "Workflow Visualizer" component from the component palette
4. Configure any settings (if applicable)
5. Save and activate the page

### Experience Cloud Sites
1. Open Experience Builder
2. Navigate to the desired page
3. Add the Workflow Visualizer component
4. Configure display settings
5. Publish the site

### Flow Screens
1. Create or edit a Flow in Flow Builder
2. Add a Screen element
3. Add the Workflow Visualizer component to the screen
4. Configure any input/output variables
5. Save and activate the flow

## Component Properties

### Public Properties (@api)
Currently, this component uses internal state management. Future versions may include:
- `initialStep`: Set the starting step (default: 1)
- `workflowData`: Custom workflow configuration
- `readOnly`: Disable interactive features

### Events

#### stepselected
Fired when a user clicks on a workflow step.

```javascript
// Event detail structure
{
    stepId: number,    // The ID of the selected step
    step: {           // Complete step object
        id: number,
        title: string,
        description: string,
        status: string,
        type: string
    }
}
```

**Usage Example:**
```html
<c-workflow-visualizer onstepselected={handleStepSelection}></c-workflow-visualizer>
```

```javascript
handleStepSelection(event) {
    const selectedStep = event.detail.step;
    console.log(`User selected: ${selectedStep.title}`);
}
```

## CSS Custom Properties

The component supports CSS custom properties for theming:

```css
/* Progress bar customization */
c-workflow-visualizer {
    --slds-c-progress-bar-color-background-fill: #0176d3;
}

/* Badge customization */
c-workflow-visualizer lightning-badge {
    --slds-c-badge-color-background: #0176d3;
    --slds-c-badge-text-color: #ffffff;
}
```

## Accessibility Features

- **Keyboard Navigation**: Full keyboard support for all interactive elements
- **Screen Reader Support**: Proper ARIA labels and descriptions
- **Focus Management**: Clear focus indicators and logical tab order
- **High Contrast Support**: Enhanced visibility in high contrast mode
- **Reduced Motion Support**: Respects user's motion preferences

### Keyboard Shortcuts
- **Tab**: Navigate between interactive elements
- **Enter/Space**: Activate buttons and clickable steps
- **Escape**: Close any modal dialogs (future feature)

## Browser Support

- Chrome 88+
- Firefox 85+
- Safari 14+
- Edge 88+
- iOS Safari 14+
- Chrome Mobile 88+

## Performance Considerations

- **Lazy Loading**: Component loads quickly with minimal initial payload
- **Event Delegation**: Efficient event handling for multiple steps
- **CSS Animations**: Hardware-accelerated animations where possible
- **Memory Management**: Proper cleanup of event listeners and timers

## Customization

### Extending the Component

To customize the workflow steps, modify the `workflowSteps` array in the JavaScript file:

```javascript
@track workflowSteps = [
    {
        id: 1,
        title: 'Custom Step',
        description: 'Your custom description',
        status: 'pending',
        type: 'process'
    }
    // Add more steps as needed
];
```

### Custom Styling

Override CSS classes to match your organization's branding:

```css
/* Custom step card styling */
.step-card {
    border-radius: 1rem;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

/* Custom color scheme */
.step-card[data-status="completed"] {
    background-color: #d4edda;
    border-color: #28a745;
}
```

## Troubleshooting

### Common Issues

1. **Component Not Visible**: Check that the permission set is assigned to users
2. **Events Not Firing**: Verify event handler syntax and method names
3. **Styling Issues**: Ensure SLDS utility classes are available
4. **Mobile Display**: Check responsive design CSS media queries

### Debug Mode

Enable debug logging by setting `this.debug = true` in the component constructor:

```javascript
constructor() {
    super();
    this.debug = true; // Enable console logging
}
```

## Security Considerations

- Component respects Salesforce sharing rules and field-level security
- No external API calls or data storage
- Client-side state management only
- Safe from XSS attacks through LWC security model

## Version History

### v1.0.0 (Current)
- Initial release with 7-step workflow visualization
- Interactive step navigation
- Responsive design
- Accessibility features
- Event dispatching for step selection

## License

This component is part of the Salesforce application and follows your organization's licensing terms.

## Support

For issues or questions about this component:
1. Check the troubleshooting section above
2. Review the Salesforce Lightning Web Components documentation
3. Contact your Salesforce administrator or development team

## Related Components

- Lightning Progress Indicator
- Lightning Progress Bar
- Lightning Card
- Lightning Button
- Lightning Icon

## API Reference

### Methods

#### `handleNextStep()`
Advances to the next workflow step if available.

#### `handlePreviousStep()`
Returns to the previous workflow step if available.

#### `handleResetWorkflow()`
Resets the workflow to the initial state (step 1 completed, others pending).

### Properties

#### `currentStep` (Number)
The currently active step ID (1-7).

#### `isLoading` (Boolean)
Indicates if the component is processing a step transition.

#### `error` (String)
Contains error message if an error occurs during operation.

#### `workflowSteps` (Array)
Array of step objects containing workflow configuration.