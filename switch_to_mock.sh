#!/bin/bash

echo "🔄 Switching to mock environment..."

# Create mock .env file
cat > .env << 'EOF'
ENVIRONMENT=development
USE_MOCK_DATA=true
ENABLE_LOGGING=true
LOG_LEVEL=debug
MOCK_RESPONSE_DELAY=300
MOCK_AUDIO_DURATION=2

# No OpenAI API key needed when using mock data
# OPENAI_API_KEY=not_needed_for_mock
EOF

echo "✅ Mock environment activated!"
echo ""
echo "🎭 Configuration:"
echo "   - Environment: development"
echo "   - Mock data: enabled"
echo "   - OpenAI API: disabled"
echo "   - Location context: enabled (with mock responses)"
echo ""
echo "💡 Mock data includes Dickens walking tour locations"
echo ""
echo "🚀 To switch to live API, run:"
echo "   ./switch_to_production.sh"

# Make sure the script is executable
chmod +x switch_to_mock.sh