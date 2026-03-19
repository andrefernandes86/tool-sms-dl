#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    echo -e "${1}${2}${NC}"
}

# Function to print header
print_header() {
    echo ""
    print_color $CYAN "=================================================="
    print_color $CYAN "  $1"
    print_color $CYAN "=================================================="
    echo ""
}

# Function to get user input with default
get_input() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        eval "$var_name=\"\${input:-$default}\""
    else
        read -p "$prompt: " input
        eval "$var_name=\"$input\""
    fi
}

# Function to get password input
get_password() {
    local prompt="$1"
    local var_name="$2"
    
    read -s -p "$prompt: " password
    echo ""
    eval "$var_name=\"$password\""
}

# Function to show menu
show_menu() {
    print_header "Security Intelligence Platform Setup"
    
    print_color $GREEN "Welcome to the Security Intelligence Platform installer!"
    echo ""
    print_color $RED "⚠️  EDUCATIONAL USE ONLY ⚠️"
    print_color $RED "This platform is for learning and educational purposes only."
    print_color $RED "Do NOT use for public data collection or malicious activities."
    echo ""
    print_color $YELLOW "This platform demonstrates comprehensive device and network information collection"
    print_color $YELLOW "including geolocation, device fingerprinting, and network intelligence."
    echo ""
    
    print_color $BLUE "Select an option:"
    echo "1) 🚀 Quick Setup (Default configuration)"
    echo "2) ⚙️  Custom Setup (Configure all options)"
    echo "3) 📊 View Current Configuration"
    echo "4) 🔧 Manage Application"
    echo "5) 🧪 Run Tests"
    echo "6) ❌ Exit"
    echo ""
}

# Function for quick setup
quick_setup() {
    print_header "Quick Setup"
    
    print_color $GREEN "Using default configuration:"
    print_color $YELLOW "- Report Password: admin123"
    print_color $YELLOW "- Application Name: Security Platform"
    print_color $YELLOW "- Port: 443 (HTTPS)"
    print_color $YELLOW "- Auto SSL: Self-signed certificate"
    echo ""
    
    # Set defaults
    REPORT_PASSWORD="admin123"
    APP_NAME="Security Platform"
    APP_PORT="443"
    SECRET_KEY=$(openssl rand -hex 32 2>/dev/null || echo "default-secret-key-$(date +%s)")
    
    deploy_application
}

# Function for custom setup
custom_setup() {
    print_header "Custom Configuration"
    
    print_color $GREEN "Configure your security platform:"
    echo ""
    
    # Application Configuration
    print_color $CYAN "📱 Application Settings"
    get_input "Application Name" "Security Platform" APP_NAME
    get_input "Application Port" "443" APP_PORT
    echo ""
    
    # Security Configuration
    print_color $CYAN "🔐 Security Settings"
    get_password "Report Dashboard Password" REPORT_PASSWORD
    
    # Generate secret key
    SECRET_KEY=$(openssl rand -hex 32 2>/dev/null || echo "default-secret-key-$(date +%s)")
    print_color $GREEN "✓ Secret key generated automatically"
    echo ""
    
    # Network Configuration
    print_color $CYAN "🌐 Network Settings"
    get_input "Bind to all interfaces? (y/n)" "y" BIND_ALL
    
    if [[ "$BIND_ALL" =~ ^[Yy]$ ]]; then
        BIND_ADDRESS="0.0.0.0"
        print_color $GREEN "✓ Will bind to all network interfaces"
    else
        get_input "Bind address" "127.0.0.1" BIND_ADDRESS
    fi
    echo ""
    
    # Data Collection Settings
    print_color $CYAN "📊 Data Collection Settings"
    get_input "Enable photo capture? (y/n)" "y" ENABLE_PHOTOS
    get_input "Enable geolocation? (y/n)" "y" ENABLE_GEOLOCATION
    get_input "Enable device fingerprinting? (y/n)" "y" ENABLE_FINGERPRINTING
    echo ""
    
    deploy_application
}

# Function to create configuration file
create_config() {
    print_color $YELLOW "📝 Creating configuration..."
    
    # Create .env file
    cat > "Smish Detector"/.env << EOF
# Application Configuration
APP_NAME=$APP_NAME
APP_PORT=$APP_PORT
BIND_ADDRESS=${BIND_ADDRESS:-0.0.0.0}

# Security Configuration
REPORT_PASSWORD=$REPORT_PASSWORD
SECRET_KEY=$SECRET_KEY

# Feature Flags
ENABLE_PHOTOS=${ENABLE_PHOTOS:-y}
ENABLE_GEOLOCATION=${ENABLE_GEOLOCATION:-y}
ENABLE_FINGERPRINTING=${ENABLE_FINGERPRINTING:-y}

# Generated at $(date)
EOF
    
    print_color $GREEN "✓ Configuration saved to 'Smish Detector'/.env"
}

# Function to deploy application
deploy_application() {
    print_header "Deployment"
    
    # Check if we need to run the installer first
    if [ ! -d "Smish Detector" ]; then
        print_color $YELLOW "📦 Running initial setup..."
        chmod +x install.sh
        ./install.sh
    fi
    
    # Create configuration
    create_config
    
    # Update docker-compose with custom settings
    print_color $YELLOW "🐳 Configuring Docker environment..."
    
    # Update docker-compose.yml
    cat > "Smish Detector"/docker-compose.yml << EOF
services:
  webapp:
    build: .
    ports:
      - "${APP_PORT}:5000"
    volumes:
      - ./uploads:/app/uploads
      - ./ssl:/app/ssl
    environment:
      - REPORT_PASSWORD=${REPORT_PASSWORD}
      - SECRET_KEY=${SECRET_KEY}
      - APP_NAME=${APP_NAME}
    restart: unless-stopped
EOF
    
    print_color $GREEN "✓ Docker configuration updated"
    
    # Deploy
    print_color $YELLOW "🚀 Starting application..."
    cd "Smish Detector"
    
    # Stop existing containers
    docker-compose down 2>/dev/null
    
    # Build and start
    if docker-compose up --build -d; then
        print_color $GREEN "✅ Application deployed successfully!"
        echo ""
        show_access_info
    else
        print_color $RED "❌ Deployment failed!"
        exit 1
    fi
    
    cd ..
}

# Function to show access information
show_access_info() {
    print_header "Access Information"
    
    # Get local IP
    LOCAL_IP=$(ifconfig 2>/dev/null | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
    
    print_color $GREEN "🌐 Access URLs:"
    echo "   Local:    https://localhost:$APP_PORT"
    echo "   Local:    https://127.0.0.1:$APP_PORT"
    if [ ! -z "$LOCAL_IP" ]; then
        echo "   Network:  https://$LOCAL_IP:$APP_PORT"
    fi
    echo ""
    
    print_color $GREEN "📊 Dashboard:"
    echo "   Reports:  [URL above]/report"
    echo "   Password: $REPORT_PASSWORD"
    echo ""
    
    print_color $GREEN "📱 Mobile Access:"
    if [ ! -z "$LOCAL_IP" ]; then
        echo "   iOS:      https://$LOCAL_IP:$APP_PORT"
        echo "   Android:  https://$LOCAL_IP:$APP_PORT"
    else
        echo "   Use network IP address for mobile access"
    fi
    echo ""
    
    print_color $YELLOW "⚠️  SSL Certificate:"
    echo "   You'll need to accept the security warning in your browser"
    echo "   This is normal for self-signed certificates"
    echo ""
    
    print_color $CYAN "🔧 Management:"
    echo "   Run './setup.sh' again to manage the application"
}

# Function to view current configuration
view_config() {
    print_header "Current Configuration"
    
    if [ -f "Smish Detector/.env" ]; then
        print_color $GREEN "Configuration file found:"
        echo ""
        cat "Smish Detector"/.env | grep -v "SECRET_KEY" | sed 's/REPORT_PASSWORD=.*/REPORT_PASSWORD=***hidden***/'
        echo ""
    else
        print_color $YELLOW "No configuration file found. Run setup first."
    fi
}

# Function to manage application
manage_app() {
    print_header "Application Management"
    
    if [ ! -d "Smish Detector" ]; then
        print_color $RED "Application not installed. Run setup first."
        return
    fi
    
    cd "Smish Detector"
    
    print_color $BLUE "Select action:"
    echo "1) 📊 Show Status"
    echo "2) 🚀 Start Application"
    echo "3) ⏹️  Stop Application"
    echo "4) 🔄 Restart Application"
    echo "5) 📋 View Logs"
    echo "6) 🧹 Clean Data"
    echo "7) ⬅️  Back to Main Menu"
    echo ""
    
    read -p "Enter choice [1-7]: " choice
    
    case $choice in
        1)
            print_color $YELLOW "📊 Application Status:"
            docker-compose ps
            ;;
        2)
            print_color $YELLOW "🚀 Starting application..."
            docker-compose up -d
            ;;
        3)
            print_color $YELLOW "⏹️ Stopping application..."
            docker-compose down
            ;;
        4)
            print_color $YELLOW "🔄 Restarting application..."
            docker-compose restart
            ;;
        5)
            print_color $YELLOW "📋 Application logs (Press Ctrl+C to exit):"
            docker-compose logs -f
            ;;
        6)
            print_color $YELLOW "🧹 Cleaning data..."
            read -p "Are you sure? This will delete all collected data (y/N): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                rm -rf uploads/photos/*
                docker-compose exec webapp rm -f /app/logs.db 2>/dev/null || true
                print_color $GREEN "✓ Data cleaned"
            fi
            ;;
        7)
            cd ..
            return
            ;;
        *)
            print_color $RED "Invalid choice"
            ;;
    esac
    
    cd ..
    echo ""
    read -p "Press Enter to continue..."
}

# Function to run tests
run_tests() {
    print_header "System Tests"
    
    if [ ! -d "Smish Detector" ]; then
        print_color $RED "Application not installed. Run setup first."
        return
    fi
    
    cd "Smish Detector"
    
    print_color $BLUE "Available tests:"
    echo "1) 🌍 Geolocation Test"
    echo "2) 📥 Download Test"
    echo "3) 📊 Data Collection Test"
    echo "4) 🔄 All Tests"
    echo "5) ⬅️  Back to Main Menu"
    echo ""
    
    read -p "Enter choice [1-5]: " choice
    
    case $choice in
        1)
            if [ -f "test-geolocation.sh" ]; then
                ./test-geolocation.sh
            else
                print_color $RED "Geolocation test not found"
            fi
            ;;
        2)
            if [ -f "test-download.sh" ]; then
                ./test-download.sh
            else
                print_color $RED "Download test not found"
            fi
            ;;
        3)
            if [ -f "test-data-collection.sh" ]; then
                ./test-data-collection.sh
            else
                print_color $RED "Data collection test not found"
            fi
            ;;
        4)
            print_color $YELLOW "Running all tests..."
            for test in test-*.sh; do
                if [ -f "$test" ]; then
                    print_color $CYAN "Running $test..."
                    ./"$test"
                    echo ""
                fi
            done
            ;;
        5)
            cd ..
            return
            ;;
        *)
            print_color $RED "Invalid choice"
            ;;
    esac
    
    cd ..
    echo ""
    read -p "Press Enter to continue..."
}

# Main menu loop
main() {
    while true; do
        show_menu
        read -p "Enter choice [1-6]: " choice
        
        case $choice in
            1)
                quick_setup
                ;;
            2)
                custom_setup
                ;;
            3)
                view_config
                read -p "Press Enter to continue..."
                ;;
            4)
                manage_app
                ;;
            5)
                run_tests
                ;;
            6)
                print_color $GREEN "Goodbye!"
                exit 0
                ;;
            *)
                print_color $RED "Invalid choice. Please try again."
                sleep 1
                ;;
        esac
    done
}

# Check dependencies
check_deps() {
    print_color $YELLOW "🔍 Checking dependencies..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_color $RED "❌ Docker not found. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_color $RED "❌ Docker Compose not found. Please install Docker Compose first."
        exit 1
    fi
    
    print_color $GREEN "✓ Dependencies check passed"
}

# Start the script
clear
check_deps
main