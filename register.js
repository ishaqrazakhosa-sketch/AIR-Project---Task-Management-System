// ====================
// REGISTRATION FUNCTIONS
// ====================

document.addEventListener('DOMContentLoaded', function() {
    console.log('Registration page loaded');
    
    // Get registration form
    const registerForm = document.getElementById('register-form');
    const registerBtn = document.getElementById('register-btn');
    const loginLink = document.getElementById('login-link');
    
    // Attach form submit handler
    if (registerForm) {
        registerForm.addEventListener('submit', handleRegistration);
        console.log('Registration form event listener attached');
    }
    
    // Handle login link
    if (loginLink) {
        loginLink.addEventListener('click', function(e) {
            e.preventDefault();
            window.location.href = '/login';
        });
    }
    
    // Auto-focus on name field
    const nameInput = document.getElementById('name');
    if (nameInput) {
        nameInput.focus();
    }
});

async function handleRegistration(event) {
    event.preventDefault();
    
    console.log('Registration attempt...');
    
    // Get form values
    const name = document.getElementById('name')?.value.trim();
    const email = document.getElementById('email')?.value.trim();
    const password = document.getElementById('password')?.value;
    const confirmPassword = document.getElementById('confirm-password')?.value;
    
    // Validation
    if (!name || !email || !password || !confirmPassword) {
        showMessage('Please fill in all fields', 'error');
        return;
    }
    
    if (name.length < 2) {
        showMessage('Name must be at least 2 characters', 'error');
        return;
    }
    
    if (!isValidEmail(email)) {
        showMessage('Please enter a valid email address', 'error');
        return;
    }
    
    if (password.length < 6) {
        showMessage('Password must be at least 6 characters', 'error');
        return;
    }
    
    if (password !== confirmPassword) {
        showMessage('Passwords do not match', 'error');
        return;
    }
    
    // Show loading state
    const registerBtn = document.getElementById('register-btn');
    const originalText = registerBtn?.textContent;
    if (registerBtn) {
        registerBtn.disabled = true;
        registerBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Creating Account...';
    }
    
    try {
        const response = await fetch('/api/register', {
            method: 'POST',
            headers: { 
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ 
                name: name,
                email: email, 
                password: password 
            })
        });
        
        const data = await response.json();
        
        // Reset button state
        if (registerBtn) {
            registerBtn.disabled = false;
            registerBtn.textContent = originalText || 'Create Account';
        }
        
        if (data.success) {
            console.log('Registration successful:', data.user);
            
            // Show success message
            showMessage('Account created successfully! Redirecting to login...', 'success');
            
            // Clear form
            document.getElementById('register-form')?.reset();
            
            // Redirect to login after delay
            setTimeout(() => {
                window.location.href = '/login';
            }, 2000);
            
        } else {
            showMessage(data.error || 'Registration failed', 'error');
            console.error('Registration failed:', data.error);
        }
        
    } catch (error) {
        console.error('Registration error:', error);
        
        // Reset button state
        if (registerBtn) {
            registerBtn.disabled = false;
            registerBtn.textContent = originalText || 'Create Account';
        }
        
        showMessage('Network error. Please try again.', 'error');
    }
}

function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

function showMessage(message, type = 'info') {
    const messageDiv = document.getElementById('register-message');
    if (!messageDiv) return;
    
    messageDiv.textContent = message;
    messageDiv.className = 'alert';
    messageDiv.classList.add(type === 'error' ? 'alert-danger' : 'alert-success');
    messageDiv.style.display = 'block';
    
    // Auto-hide after 5 seconds
    setTimeout(() => {
        messageDiv.style.display = 'none';
    }, 5000);
}