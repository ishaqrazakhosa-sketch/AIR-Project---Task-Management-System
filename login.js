// ====================
// LOGIN FUNCTIONS
// ====================

document.addEventListener('DOMContentLoaded', function() {
    console.log('Login page loaded');
    
    // Get login form
    const loginForm = document.getElementById('login-form');
    const loginBtn = document.getElementById('login-btn');
    const registerLink = document.getElementById('register-link');
    
    // Attach form submit handler
    if (loginForm) {
        loginForm.addEventListener('submit', handleLogin);
        console.log('Login form event listener attached');
    }
    
    // Handle register link
    if (registerLink) {
        registerLink.addEventListener('click', function(e) {
            e.preventDefault();
            window.location.href = '/register';
        });
    }
    
    // Auto-focus on email field
    const emailInput = document.getElementById('email');
    if (emailInput) {
        emailInput.focus();
    }
});

async function handleLogin(event) {
    event.preventDefault();
    
    console.log('Login attempt...');
    
    // Get form values
    const email = document.getElementById('email')?.value.trim();
    const password = document.getElementById('password')?.value;
    
    // Validation
    if (!email || !password) {
        showMessage('Please fill in all fields', 'error');
        return;
    }
    
    if (!isValidEmail(email)) {
        showMessage('Please enter a valid email address', 'error');
        return;
    }
    
    // Show loading state
    const loginBtn = document.getElementById('login-btn');
    const originalText = loginBtn?.textContent;
    if (loginBtn) {
        loginBtn.disabled = true;
        loginBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Logging in...';
    }
    
    try {
        const response = await fetch('/api/login', {
            method: 'POST',
            headers: { 
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ 
                email: email, 
                password: password 
            })
        });
        
        const data = await response.json();
        
        // Reset button state
        if (loginBtn) {
            loginBtn.disabled = false;
            loginBtn.textContent = originalText || 'Login';
        }
        
        if (data.success) {
            console.log('Login successful:', data.user);
            
            // Save user data to localStorage
            localStorage.setItem('userId', data.user.id);
            localStorage.setItem('userName', data.user.name);
            localStorage.setItem('userEmail', data.user.email);
            // REMOVED: sessionToken since backend doesn't return it anymore
            
            // Show success message
            showMessage('Login successful! Redirecting...', 'success');
            
            // Redirect to dashboard after delay
            setTimeout(() => {
                window.location.href = '/dashboard';
            }, 1000);
            
        } else {
            showMessage(data.error || 'Invalid email or password', 'error');
            console.error('Login failed:', data.error);
        }
        
    } catch (error) {
        console.error('Login error:', error);
        
        // Reset button state
        if (loginBtn) {
            loginBtn.disabled = false;
            loginBtn.textContent = originalText || 'Login';
        }
        
        showMessage('Network error. Please try again.', 'error');
    }
}

function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

function showMessage(message, type = 'info') {
    const messageDiv = document.getElementById('login-message') || 
                      document.querySelector('.alert') ||
                      (function() {
                          // Create message div if it doesn't exist
                          const div = document.createElement('div');
                          div.id = 'login-message';
                          div.className = 'alert';
                          
                          const form = document.getElementById('login-form') || 
                                      document.querySelector('.auth-card') ||
                                      document.querySelector('.card-body');
                          if (form) {
                              form.insertBefore(div, form.firstChild);
                          }
                          return div;
                      })();
    
    messageDiv.textContent = message;
    messageDiv.className = 'alert';
    messageDiv.classList.add(type === 'error' ? 'alert-danger' : 'alert-success');
    messageDiv.style.display = 'block';
    
    // Auto-hide after 5 seconds
    setTimeout(() => {
        messageDiv.style.display = 'none';
    }, 5000);
}