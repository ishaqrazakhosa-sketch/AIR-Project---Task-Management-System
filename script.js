// ====================
// CONFIGURATION
// ====================
const API_BASE = '/api';
let currentTasks = [];

// ====================
// UTILITY FUNCTIONS
// ====================
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function showNotification(message, type = 'info') {
    // Create or update notification element
    let notification = document.getElementById('global-notification');
    if (!notification) {
        notification = document.createElement('div');
        notification.id = 'global-notification';
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 15px 20px;
            border-radius: 5px;
            color: white;
            z-index: 1000;
            display: none;
            font-weight: bold;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        `;
        document.body.appendChild(notification);
    }
    
    notification.textContent = message;
    notification.style.backgroundColor = type === 'success' ? '#28a745' : 
                                       type === 'error' ? '#dc3545' : '#17a2b8';
    notification.style.display = 'block';
    
    setTimeout(() => {
        notification.style.display = 'none';
    }, 3000);
}

// ====================
// AUTH FUNCTIONS - UPDATED
// ====================
function checkAuth() {
    const userId = localStorage.getItem('userId');
    if (!userId) {
        console.warn('User not authenticated - no userId in localStorage');
        return false;
    }
    return true;
}

async function logoutUser() {
    console.log('Logging out...');
    
    try {
        // SIMPLIFIED: No need to send user_id since backend doesn't use it anymore
        const response = await fetch(`${API_BASE}/logout`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
            // REMOVED: body: JSON.stringify({ user_id: userId })
        });
        
        const data = await response.json();
        
        if (data.success) {
            // Clear local storage
            localStorage.clear();
            showNotification('Logged out successfully!', 'success');
            // Redirect to login page
            setTimeout(() => {
                window.location.href = '/login';
            }, 500);
        } else {
            throw new Error(data.error || 'Logout failed');
        }
    } catch (error) {
        console.error('Logout error:', error);
        // Still clear storage and redirect
        localStorage.clear();
        window.location.href = '/login';
    }
}

// ====================
// TASK DISPLAY FUNCTIONS
// ====================
function displayTasks(tasks) {
    console.log("Displaying tasks:", tasks);
    
    const taskList = document.getElementById('tasksContainer'); // FIXED: Changed from 'task-list' to 'tasksContainer'
    const emptyState = document.getElementById('empty-state');
    const taskStats = document.getElementById('task-stats');
    
    if (!taskList) {
        console.error("Task list element not found! Looking for 'tasksContainer'");
        return;
    }
    
    // Clear current tasks
    taskList.innerHTML = '';
    
    // Update stats if element exists
    if (taskStats) {
        const total = tasks.length;
        const completed = tasks.filter(t => t.completed).length;
        const pending = total - completed;
        
        taskStats.innerHTML = `
            <div class="stat">
                <h3>${total}</h3>
                <p>Total Tasks</p>
            </div>
            <div class="stat">
                <h3>${completed}</h3>
                <p>Completed</p>
            </div>
            <div class="stat">
                <h3>${pending}</h3>
                <p>Pending</p>
            </div>
        `;
    }
    
    // If no tasks, show empty state
    if (tasks.length === 0) {
        if (emptyState) {
            emptyState.style.display = 'block';
        }
        taskList.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-tasks"></i>
                <h3>No tasks yet</h3>
                <p>Click "Add Task" to create your first task</p>
            </div>
        `;
        return;
    }
    
    // Hide empty state if exists
    if (emptyState) {
        emptyState.style.display = 'none';
    }
    
    // Render each task
    tasks.forEach(task => {
        const taskElement = createTaskElement(task);
        taskList.appendChild(taskElement);
    });
}

function createTaskElement(task) {
    const div = document.createElement('div');
    div.className = `task-item ${task.completed ? 'completed' : ''}`; // FIXED: Changed from 'task-card' to 'task-item'
    div.dataset.id = task.id;
    
    // Priority colors
    const priorityColors = {
        'high': '#dc3545',
        'medium': '#ffc107', 
        'low': '#28a745'
    };
    
    // Format date
    let dueDateText = 'No due date';
    let isOverdue = false;
    if (task.due_date) {
        const dueDate = new Date(task.due_date);
        dueDateText = dueDate.toLocaleDateString('en-US', {
            weekday: 'short',
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
        
        // Check if overdue
        if (!task.completed && dueDate < new Date()) {
            isOverdue = true;
            dueDateText = 'Overdue: ' + dueDateText;
        }
    }
    
    // FIXED: Updated HTML structure to match your dashboard.html
    div.innerHTML = `
        <div class="task-header">
            <div class="task-title">
                <div class="task-checkbox ${task.completed ? 'checked' : ''}" onclick="toggleTaskCompletion(${task.id}, ${!task.completed})"></div>
                <h3>${escapeHtml(task.title)}</h3>
            </div>
            <span class="task-priority priority-${task.priority}">
                ${task.priority.charAt(0).toUpperCase() + task.priority.slice(1)}
            </span>
        </div>
        ${task.description ? `<div class="task-description">${escapeHtml(task.description)}</div>` : ''}
        <div class="task-footer">
            <div class="task-meta">
                <span><i class="far fa-calendar"></i> ${dueDateText}</span>
            </div>
            <div class="task-actions">
                <button class="task-btn btn-edit" onclick="editTask(${task.id})">
                    <i class="fas fa-edit"></i>
                </button>
                <button class="task-btn btn-delete" onclick="deleteTask(${task.id})">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
        </div>
    `;
    
    return div;
}

// ====================
// TASK CRUD FUNCTIONS
// ====================
async function getTasks() {
    if (!checkAuth()) {
        console.warn('Not authenticated in getTasks');
        displayTasks([]);
        return;
    }

    try {
        const userId = localStorage.getItem('userId');
        console.log(`🔍 Fetching tasks for user ${userId}...`);

        const response = await fetch(`${API_BASE}/tasks?user_id=${userId}`);
        const data = await response.json();
        
        if (!data.success) {
            console.error(`API error: ${data.error}`);
            if (response.status === 401) {
                localStorage.clear();
                window.location.href = '/login';
            }
            return;
        }

        console.log(`✅ Loaded ${data.tasks?.length || 0} tasks`);
        
        // Store tasks globally
        currentTasks = data.tasks || [];
        
        // Display tasks
        displayTasks(currentTasks);
        
        // Update dashboard stats
        updateDashboardStats();
        
    } catch (error) {
        console.error('❌ Error loading tasks:', error);
        displayTasks([]);
        showNotification('Failed to load tasks', 'error');
    }
}

async function toggleTaskCompletion(taskId, completed) {
    try {
        const response = await fetch(`${API_BASE}/tasks/${taskId}/toggle`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' }
        });
        
        const data = await response.json();
        
        if (data.success) {
            await getTasks();
            showNotification('Task updated!', 'success');
        } else {
            showNotification(data.error || 'Failed to update task', 'error');
        }
    } catch (error) {
        console.error('Error toggling task:', error);
        showNotification('Failed to update task', 'error');
    }
}

async function deleteTask(taskId) {
    if (!confirm('Are you sure you want to delete this task?')) {
        return;
    }
    
    try {
        const response = await fetch(`${API_BASE}/tasks/${taskId}`, {
            method: 'DELETE',
            headers: { 'Content-Type': 'application/json' }
        });
        
        const data = await response.json();
        
        if (data.success) {
            // Remove from local array
            currentTasks = currentTasks.filter(task => task.id !== taskId);
            // Refresh display
            displayTasks(currentTasks);
            showNotification('Task deleted successfully!', 'success');
        } else {
            showNotification(data.error || 'Failed to delete task', 'error');
        }
    } catch (error) {
        console.error('Error deleting task:', error);
        showNotification('Failed to delete task', 'error');
    }
}

function editTask(taskId) {
    const task = currentTasks.find(t => t.id == taskId);
    if (!task) return;
    
    // Create edit modal using YOUR modal structure
    const editModal = document.createElement('div');
    editModal.className = 'modal';
    editModal.id = 'edit-task-modal';
    editModal.innerHTML = `
        <div class="modal-content">
            <span class="close-modal">&times;</span>
            <h2>Edit Task</h2>
            <form id="edit-task-form">
                <div class="form-group">
                    <label for="edit-task-title">Task Title</label>
                    <input type="text" id="edit-task-title" value="${escapeHtml(task.title)}" required>
                </div>
                <div class="form-group">
                    <label for="edit-task-description">Description</label>
                    <textarea id="edit-task-description" rows="3">${escapeHtml(task.description || '')}</textarea>
                </div>
                <div class="form-group">
                    <label for="edit-task-due-date">Due Date</label>
                    <input type="datetime-local" id="edit-task-due-date" 
                           value="${task.due_date ? new Date(task.due_date).toISOString().slice(0, 16) : ''}">
                </div>
                <div class="form-group">
                    <label for="edit-task-priority">Priority</label>
                    <select id="edit-task-priority">
                        <option value="low" ${task.priority === 'low' ? 'selected' : ''}>Low Priority</option>
                        <option value="medium" ${task.priority === 'medium' ? 'selected' : ''}>Medium Priority</option>
                        <option value="high" ${task.priority === 'high' ? 'selected' : ''}>High Priority</option>
                    </select>
                </div>
                <div class="form-actions">
                    <button type="submit" class="btn-save">Update Task</button>
                    <button type="button" class="btn-cancel">Cancel</button>
                </div>
            </form>
        </div>
    `;
    
    document.body.appendChild(editModal);
    editModal.style.display = 'flex';
    
    // Close modal handlers
    const closeBtn = editModal.querySelector('.close-modal');
    const cancelBtn = editModal.querySelector('.btn-cancel');
    
    closeBtn.onclick = () => editModal.remove();
    cancelBtn.onclick = () => editModal.remove();
    
    editModal.onclick = (e) => {
        if (e.target === editModal) editModal.remove();
    };
    
    // Form submission
    const editForm = editModal.querySelector('#edit-task-form');
    editForm.onsubmit = async (e) => {
        e.preventDefault();
        
        const updates = {
            title: document.getElementById('edit-task-title').value.trim(),
            description: document.getElementById('edit-task-description').value.trim() || null,
            priority: document.getElementById('edit-task-priority').value
        };
        
        const dueDate = document.getElementById('edit-task-due-date').value;
        if (dueDate) {
            updates.due_date = new Date(dueDate).toISOString();
        } else {
            updates.due_date = null;
        }
        
        try {
            const response = await fetch(`${API_BASE}/tasks/${taskId}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(updates)
            });
            
            const data = await response.json();
            
            if (data.success) {
                editModal.remove();
                await getTasks();
                showNotification('Task updated successfully!', 'success');
            } else {
                showNotification(data.error || 'Failed to update task', 'error');
            }
        } catch (error) {
            console.error('Error updating task:', error);
            showNotification('Failed to update task', 'error');
        }
    };
}

// ====================
// DASHBOARD FUNCTIONS
// ====================
function updateDashboardStats() {
    const total = currentTasks.length;
    const completed = currentTasks.filter(t => t.completed).length;
    const pending = total - completed;
    
    // FIXED: Updated IDs to match your dashboard.html
    const elements = {
        'totalTasks': total,
        'pendingTasks': pending,
        'completedTasks': completed
    };
    
    for (const [id, value] of Object.entries(elements)) {
        const element = document.getElementById(id);
        if (element) {
            element.textContent = value;
        }
    }
}

// ====================
// EVENT LISTENERS SETUP - FIXED FOR YOUR HTML
// ====================
function setupEventListeners() {
    console.log('Setting up event listeners...');
    
    // Logout button
    const logoutBtn = document.getElementById('logoutBtn');
    if (logoutBtn) {
        logoutBtn.addEventListener('click', logoutUser);
        console.log('✅ Logout button listener added');
    } else {
        console.warn('❌ Logout button not found!');
    }
    
    // =========== CRITICAL FIX: Handle YOUR Add Task buttons ===========
    const addTaskBtn1 = document.getElementById('addTaskBtn'); // Sidebar button
    const addTaskBtn2 = document.getElementById('addTaskBtnMain'); // Main header button
    
    console.log('🔍 Found Add Task buttons:', {
        sidebarButton: !!addTaskBtn1,
        mainButton: !!addTaskBtn2
    });
    
    // Function to show YOUR modal (#taskModal from your HTML)
    function showAddTaskModal() {
        const modal = document.getElementById('taskModal');
        if (modal) {
            modal.style.display = 'flex';
            document.body.style.overflow = 'hidden';
            console.log('✅ Modal shown (#taskModal)');
            
            // Add submit handler for YOUR form
            const taskForm = document.getElementById('taskForm');
            if (taskForm && !taskForm.dataset.listenerAdded) {
                taskForm.addEventListener('submit', async function(e) {
                    e.preventDefault();
                    
                    const userId = localStorage.getItem('userId');
                    const title = document.getElementById('taskTitle').value.trim();
                    const description = document.getElementById('taskDesc').value.trim();
                    const dueDate = document.getElementById('dueDate').value;
                    const priority = document.getElementById('taskPriority').value;
                    
                    if (!title) {
                        alert('Task title is required!');
                        return;
                    }
                    
                    const taskData = {
                        user_id: parseInt(userId),
                        title: title,
                        description: description || null,
                        priority: priority,
                        due_date: dueDate || null
                    };
                    
                    try {
                        const response = await fetch(`${API_BASE}/tasks`, {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify(taskData)
                        });
                        
                        const data = await response.json();
                        
                        if (data.success) {
                            showNotification('Task added successfully!', 'success');
                            modal.style.display = 'none';
                            document.body.style.overflow = 'auto';
                            taskForm.reset();
                            await getTasks();
                        } else {
                            showNotification(data.error || 'Failed to add task', 'error');
                        }
                    } catch (error) {
                        console.error('Error adding task:', error);
                        showNotification('Failed to add task', 'error');
                    }
                });
                taskForm.dataset.listenerAdded = 'true';
                console.log('✅ Task form listener added');
            }
        } else {
            console.error('❌ Modal not found! Looking for #taskModal');
            alert('Cannot open task modal. Please refresh the page.');
        }
    }
    
    // Add click handlers to BOTH buttons
    if (addTaskBtn1) {
        addTaskBtn1.addEventListener('click', showAddTaskModal);
        console.log('✅ Sidebar Add Task button listener added');
    }
    
    if (addTaskBtn2) {
        addTaskBtn2.addEventListener('click', showAddTaskModal);
        console.log('✅ Main Add Task button listener added');
    }
    
    // Close YOUR modal buttons
    const closeModalBtn = document.querySelector('.close-modal');
    const cancelBtn = document.querySelector('.btn-cancel');
    
    if (closeModalBtn) {
        closeModalBtn.addEventListener('click', function() {
            document.getElementById('taskModal').style.display = 'none';
            document.body.style.overflow = 'auto';
        });
        console.log('✅ Close modal button listener added');
    }
    
    if (cancelBtn) {
        cancelBtn.addEventListener('click', function() {
            document.getElementById('taskModal').style.display = 'none';
            document.body.style.overflow = 'auto';
        });
        console.log('✅ Cancel button listener added');
    }
    
    // Close modal when clicking outside
    const taskModal = document.getElementById('taskModal');
    if (taskModal) {
        taskModal.addEventListener('click', function(event) {
            if (event.target === taskModal) {
                taskModal.style.display = 'none';
                document.body.style.overflow = 'auto';
            }
        });
    }
    
    // Filter tasks - using YOUR filter buttons
    const filterButtons = document.querySelectorAll('.filter-btn');
    filterButtons.forEach(btn => {
        btn.addEventListener('click', async function() {
            const filter = this.dataset.filter;
            const userId = localStorage.getItem('userId');
            
            let url = `${API_BASE}/tasks?user_id=${userId}`;
            if (filter === 'pending') {
                url += '&completed=false';
            } else if (filter === 'completed') {
                url += '&completed=true';
            } else if (filter === 'today') {
                // Today filter logic would go here
                console.log('Today filter selected');
            }
            
            try {
                const response = await fetch(url);
                const data = await response.json();
                
                if (data.success) {
                    // Update active filter button
                    filterButtons.forEach(b => b.classList.remove('active'));
                    this.classList.add('active');
                    
                    // Display filtered tasks
                    displayTasks(data.tasks || []);
                }
            } catch (error) {
                console.error('Error filtering tasks:', error);
            }
        });
    });
}

// ====================
// INITIALIZATION
// ====================
document.addEventListener('DOMContentLoaded', function() {
    console.log('✅ Dashboard DOM loaded');
    console.log('Current user ID:', localStorage.getItem('userId'));
    console.log('Current user name:', localStorage.getItem('userName'));
    
    // Update welcome message (if element exists)
    const welcomeMsg = document.getElementById('welcome-message');
    const userName = localStorage.getItem('userName');
    if (welcomeMsg && userName) {
        welcomeMsg.textContent = `Welcome back, ${userName}!`;
    }
    
    // Check authentication
    if (!checkAuth()) {
        console.warn('User not authenticated, redirecting to login');
        window.location.href = '/login';
        return;
    }
    
    // Load tasks
    getTasks();
    
    // Setup event listeners
    setTimeout(() => {
        setupEventListeners();
    }, 100);
    
    // Make functions globally available for inline onclick handlers
    window.toggleTaskCompletion = toggleTaskCompletion;
    window.deleteTask = deleteTask;
    window.editTask = editTask;
});

// ====================
// DEBUG INFO
// ====================
console.log("✅ script.js is loaded!");