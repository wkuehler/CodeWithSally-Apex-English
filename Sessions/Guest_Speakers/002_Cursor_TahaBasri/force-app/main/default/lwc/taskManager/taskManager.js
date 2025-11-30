import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTasks from '@salesforce/apex/TaskManagerApexController.getTasks';
import closeTask from '@salesforce/apex/TaskManagerApexController.closeTask';
import deferTask from '@salesforce/apex/TaskManagerApexController.deferTask';

export default class TaskManager extends LightningElement {
    groupedTasks = [];
    isLoading = false;

    connectedCallback() {
        this.loadTasks();
    }

    // Load tasks from Apex controller
    loadTasks() {
        this.isLoading = true;
        getTasks()
            .then(result => {
                this.processTasks(result);
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error loading tasks:', error);
                this.showToast('Error', 'Failed to load tasks. Please try again.', 'error');
                this.isLoading = false;
            });
    }

    // Process tasks from Apex into format needed for template
    processTasks(tasksMap) {
        // Convert Map to array format for template iteration
        this.groupedTasks = [
            { key: 'overdue', label: 'Overdue', tasks: this.formatTasks(tasksMap['Overdue'] || []) },
            { key: 'today', label: 'Today', tasks: this.formatTasks(tasksMap['Today'] || []) },
            { key: 'tomorrow', label: 'Tomorrow', tasks: this.formatTasks(tasksMap['Tomorrow'] || []) },
            { key: 'thisWeek', label: 'This Week', tasks: this.formatTasks(tasksMap['This Week'] || []) },
            { key: 'nextWeek', label: 'Next Week', tasks: this.formatTasks(tasksMap['Next Week'] || []) },
            { key: 'later', label: 'Later', tasks: this.formatTasks(tasksMap['Later'] || []) }
        ];
    }

    // Format tasks for display
    formatTasks(tasks) {
        return tasks.map(task => ({
            id: task.Id,
            subject: task.Subject,
            priority: task.Priority || 'Normal',
            activityDate: task.ActivityDate ? new Date(task.ActivityDate) : null,
            formattedDate: this.formatDate(task.ActivityDate),
            priorityBadgeClass: this.getPriorityBadgeClass(task.Priority)
        }));
    }

    // Format date for display
    formatDate(dateString) {
        if (!dateString) return 'No due date';
        
        const date = new Date(dateString);
        const today = new Date();
        const dateOnly = new Date(date.getFullYear(), date.getMonth(), date.getDate());
        const todayOnly = new Date(today.getFullYear(), today.getMonth(), today.getDate());
        
        const diffTime = dateOnly - todayOnly;
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        
        if (diffDays === 0) return 'Today';
        if (diffDays === 1) return 'Tomorrow';
        if (diffDays === -1) return 'Yesterday';
        if (diffDays < 0) return `${Math.abs(diffDays)} days ago`;
        
        return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
    }

    // Get priority badge CSS class
    getPriorityBadgeClass(priority) {
        const priorityMap = {
            'High': 'slds-badge_inverse',
            'Normal': '',
            'Low': 'slds-badge_lightest'
        };
        return priorityMap[priority] || '';
    }

    // Handle defer action
    handleDefer(event) {
        const taskId = event.currentTarget.dataset.taskId;
        if (!taskId) return;

        // Disable button during operation
        const button = event.currentTarget;
        button.disabled = true;

        deferTask({ taskId: taskId })
            .then(result => {
                if (result) {
                    this.showToast('Success', 'Task deferred to tomorrow', 'success');
                    // Reload tasks to reflect the change
                    this.loadTasks();
                } else {
                    this.showToast('Error', 'Failed to defer task', 'error');
                    button.disabled = false;
                }
            })
            .catch(error => {
                console.error('Error deferring task:', error);
                this.showToast('Error', 'Failed to defer task. Please try again.', 'error');
                button.disabled = false;
            });
    }

    // Handle complete action
    handleComplete(event) {
        const taskId = event.currentTarget.dataset.taskId;
        if (!taskId) return;

        // Disable button during operation
        const button = event.currentTarget;
        button.disabled = true;

        closeTask({ taskId: taskId })
            .then(result => {
                if (result) {
                    this.showToast('Success', 'Task completed', 'success');
                    // Reload tasks to remove completed task
                    this.loadTasks();
                } else {
                    this.showToast('Error', 'Failed to complete task', 'error');
                    button.disabled = false;
                }
            })
            .catch(error => {
                console.error('Error completing task:', error);
                this.showToast('Error', 'Failed to complete task. Please try again.', 'error');
                button.disabled = false;
            });
    }

    // Show toast notification
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}
