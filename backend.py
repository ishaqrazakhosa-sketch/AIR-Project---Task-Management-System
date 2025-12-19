from flask import Flask, request, jsonify, send_from_directory
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from datetime import datetime
import os

app = Flask(__name__, static_folder='frontend')
CORS(app)

# Database configuration
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://root:pMYSQL123@localhost/air_project'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = 'air-project-secret-key-2025'

db = SQLAlchemy(app)

# Models - REMOVED session_token to match your existing database
class User(db.Model):
    __tablename__ = 'air_users'
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    created_at = db.Column(db.TIMESTAMP, server_default=db.func.current_timestamp())
    updated_at = db.Column(db.TIMESTAMP, server_default=db.func.current_timestamp(), onupdate=db.func.current_timestamp())
    
    def to_dict(self):
        return {
            'id': self.id,
            'email': self.email,
            'name': self.name,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

class Task(db.Model):
    __tablename__ = 'air_tasks'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('air_users.id'), nullable=False)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    due_date = db.Column(db.DateTime)
    priority = db.Column(db.Enum('low', 'medium', 'high'), default='medium')
    completed = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.TIMESTAMP, server_default=db.func.current_timestamp())
    updated_at = db.Column(db.TIMESTAMP, server_default=db.func.current_timestamp(), onupdate=db.func.current_timestamp())
    
    user = db.relationship('User', backref=db.backref('tasks', lazy=True))
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'title': self.title,
            'description': self.description,
            'due_date': self.due_date.isoformat() if self.due_date else None,
            'priority': self.priority,
            'completed': self.completed,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }

# Create tables within app context
with app.app_context():
    try:
        db.create_all()
        print("✅ Database tables created successfully!")
        print("📊 Tables: air_users, air_tasks")
    except Exception as e:
        print(f"⚠️ Database warning: {e}")
        print("⚠️ Using existing database structure...")

# Frontend Routes
@app.route('/')
def serve_home():
    return send_from_directory('frontend', 'index.html')

@app.route('/login')
def serve_login():
    return send_from_directory('frontend', 'login.html')

@app.route('/register')
def serve_register():
    return send_from_directory('frontend', 'register.html')

@app.route('/dashboard')
def serve_dashboard():
    return send_from_directory('frontend', 'dashboard.html')

@app.route('/css/<path:filename>')
def serve_css(filename):
    return send_from_directory('frontend/css', filename)

@app.route('/js/<path:filename>')
def serve_js(filename):
    return send_from_directory('frontend/js', filename)

# API Routes
@app.route('/api/test', methods=['GET'])
def test():
    return jsonify({
        'success': True,
        'message': 'AIR Project Server is running!', 
        'database': 'MySQL', 
        'tables': 'air_users, air_tasks',
        'status': '✅ Operational'
    })

@app.route('/api/register', methods=['POST'])
def register():
    try:
        data = request.json
        email = data.get('email')
        password = data.get('password')
        name = data.get('name')
        
        if not email or not password or not name:
            return jsonify({'success': False, 'error': 'All fields are required'}), 400
        
        if User.query.filter_by(email=email).first():
            return jsonify({'success': False, 'error': 'Email already exists'}), 400
        
        new_user = User(email=email, password=password, name=name)
        db.session.add(new_user)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'User registered successfully',
            'user': new_user.to_dict()
        })
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/login', methods=['POST'])
def api_login():
    try:
        data = request.json
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return jsonify({'success': False, 'error': 'Email and password required'}), 400
        
        user = User.query.filter_by(email=email, password=password).first()
        if not user:
            return jsonify({'success': False, 'error': 'Invalid email or password'}), 401
        
        return jsonify({
            'success': True,
            'message': 'Login successful',
            'user': user.to_dict()
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/logout', methods=['POST'])
def logout():
    try:
        return jsonify({
            'success': True,
            'message': 'Logged out successfully'
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/check-auth', methods=['GET'])
def check_auth():
    try:
        user_id = request.args.get('user_id', type=int)
        
        if user_id:
            user = User.query.get(user_id)
            if user:
                return jsonify({
                    'success': True,
                    'authenticated': True,
                    'user': user.to_dict()
                })
        
        return jsonify({
            'success': True,
            'authenticated': False,
            'message': 'Not authenticated'
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# Task Management Routes
@app.route('/api/tasks', methods=['GET'])
def get_tasks():
    try:
        user_id = request.args.get('user_id', type=int)
        if not user_id:
            return jsonify({'success': False, 'error': 'User ID required'}), 400
        
        # Validate user exists
        user = User.query.get(user_id)
        if not user:
            return jsonify({'success': False, 'error': 'User not found'}), 404
        
        # Get filter parameters
        completed = request.args.get('completed', type=str)
        priority = request.args.get('priority', type=str)
        search = request.args.get('search', type=str)
        
        # Build query
        query = Task.query.filter_by(user_id=user_id)
        
        if completed:
            if completed.lower() == 'true':
                query = query.filter_by(completed=True)
            elif completed.lower() == 'false':
                query = query.filter_by(completed=False)
        
        if priority and priority in ['low', 'medium', 'high']:
            query = query.filter_by(priority=priority)
        
        if search:
            query = query.filter(Task.title.ilike(f'%{search}%') | 
                                Task.description.ilike(f'%{search}%'))
        
        # Order by due date (nulls last) and priority
        tasks = query.order_by(
            db.case((Task.due_date.is_(None), 1), else_=0),
            Task.due_date.asc(),
            db.case(
                (Task.priority == 'high', 1),
                (Task.priority == 'medium', 2),
                (Task.priority == 'low', 3),
                else_=4
            )
        ).all()
        
        return jsonify({
            'success': True,
            'tasks': [task.to_dict() for task in tasks],
            'count': len(tasks)
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/tasks', methods=['POST'])
def create_task():
    try:
        data = request.json
        user_id = data.get('user_id')
        
        if not user_id:
            return jsonify({'success': False, 'error': 'User ID required'}), 400
        
        # Validate required fields
        if not data.get('title'):
            return jsonify({'success': False, 'error': 'Task title is required'}), 400
        
        # Validate user exists
        user = User.query.get(user_id)
        if not user:
            return jsonify({'success': False, 'error': 'User not found'}), 404
        
        # Parse due date
        due_date = None
        if data.get('due_date'):
            try:
                due_date = datetime.fromisoformat(data['due_date'].replace('Z', '+00:00'))
            except ValueError:
                # Try alternative format
                try:
                    due_date = datetime.strptime(data['due_date'], '%Y-%m-%d')
                except ValueError:
                    return jsonify({'success': False, 'error': 'Invalid date format. Use YYYY-MM-DD'}), 400
        
        new_task = Task(
            user_id=user_id,
            title=data['title'],
            description=data.get('description', ''),
            due_date=due_date,
            priority=data.get('priority', 'medium'),
            completed=data.get('completed', False)
        )
        
        db.session.add(new_task)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Task created successfully',
            'task': new_task.to_dict()
        })
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/tasks/<int:task_id>', methods=['GET'])
def get_single_task(task_id):
    try:
        task = Task.query.get(task_id)
        if not task:
            return jsonify({'success': False, 'error': 'Task not found'}), 404
        
        return jsonify({
            'success': True,
            'task': task.to_dict()
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/tasks/<int:task_id>', methods=['PUT'])
def update_task(task_id):
    try:
        data = request.json
        task = Task.query.get(task_id)
        
        if not task:
            return jsonify({'success': False, 'error': 'Task not found'}), 404
        
        # Update fields if provided
        if 'title' in data:
            if not data['title'].strip():
                return jsonify({'success': False, 'error': 'Task title cannot be empty'}), 400
            task.title = data['title'].strip()
        
        if 'description' in data:
            task.description = data['description'].strip() if data['description'] else ''
        
        if 'priority' in data:
            if data['priority'] not in ['low', 'medium', 'high']:
                return jsonify({'success': False, 'error': 'Invalid priority value'}), 400
            task.priority = data['priority']
        
        if 'due_date' in data:
            if data['due_date']:
                try:
                    task.due_date = datetime.fromisoformat(data['due_date'].replace('Z', '+00:00'))
                except ValueError:
                    try:
                        task.due_date = datetime.strptime(data['due_date'], '%Y-%m-%d')
                    except ValueError:
                        return jsonify({'success': False, 'error': 'Invalid date format'}), 400
            else:
                task.due_date = None
        
        if 'completed' in data:
            task.completed = bool(data['completed'])
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Task updated successfully',
            'task': task.to_dict()
        })
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/tasks/<int:task_id>/toggle', methods=['PUT'])
def toggle_task_completion(task_id):
    try:
        task = Task.query.get(task_id)
        if not task:
            return jsonify({'success': False, 'error': 'Task not found'}), 404
        
        # Toggle the completion status
        task.completed = not task.completed
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Task updated successfully',
            'completed': task.completed
        })
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/tasks/<int:task_id>', methods=['DELETE'])
def delete_task(task_id):
    try:
        task = Task.query.get(task_id)
        if not task:
            return jsonify({'success': False, 'error': 'Task not found'}), 404
        
        db.session.delete(task)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Task deleted successfully'
        })
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/dashboard-stats', methods=['GET'])
def get_dashboard_stats():
    try:
        user_id = request.args.get('user_id', type=int)
        if not user_id:
            return jsonify({'success': False, 'error': 'User ID required'}), 400
        
        # Total tasks
        total_tasks = Task.query.filter_by(user_id=user_id).count()
        
        # Completed tasks
        completed_tasks = Task.query.filter_by(user_id=user_id, completed=True).count()
        
        # Pending tasks
        pending_tasks = Task.query.filter_by(user_id=user_id, completed=False).count()
        
        # Tasks by priority
        high_priority = Task.query.filter_by(user_id=user_id, priority='high', completed=False).count()
        medium_priority = Task.query.filter_by(user_id=user_id, priority='medium', completed=False).count()
        low_priority = Task.query.filter_by(user_id=user_id, priority='low', completed=False).count()
        
        # Overdue tasks (due date is in the past and not completed)
        overdue_tasks = Task.query.filter(
            Task.user_id == user_id,
            Task.completed == False,
            Task.due_date.isnot(None),
            Task.due_date < datetime.now()
        ).count()
        
        return jsonify({
            'success': True,
            'stats': {
                'total_tasks': total_tasks,
                'completed_tasks': completed_tasks,
                'pending_tasks': pending_tasks,
                'overdue_tasks': overdue_tasks,
                'priority_breakdown': {
                    'high': high_priority,
                    'medium': medium_priority,
                    'low': low_priority
                },
                'completion_rate': round((completed_tasks / total_tasks * 100) if total_tasks > 0 else 0, 1)
            }
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({
        'success': False,
        'error': 'Resource not found',
        'message': str(error)
    }), 404

@app.errorhandler(500)
def server_error(error):
    return jsonify({
        'success': False,
        'error': 'Internal server error',
        'message': str(error) if app.debug else 'An internal error occurred'
    }), 500

if __name__ == '__main__':
    print("=" * 70)
    print("🚀 AIR PROJECT - Intelligent Task Management System")
    print("=" * 70)
    print("🌐 Server URL: http://localhost:5000")
    print("📡 API Endpoints:")
    print("   /api/register    - User registration")
    print("   /api/login       - User login")
    print("   /api/logout      - User logout")
    print("   /api/tasks       - Task management (GET, POST)")
    print("   /api/tasks/:id   - Single task operations (GET, PUT, DELETE)")
    print("   /api/tasks/:id/toggle - Toggle task completion")
    print("   /api/dashboard-stats - Get dashboard statistics")
    print("   /api/check-auth  - Check authentication status")
    print("   /dashboard       - Main dashboard")
    print("=" * 70)
    app.run(debug=True, host='0.0.0.0', port=5000)