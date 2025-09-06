#!/bin/bash

echo "🔄 Switching to production environment..."

# Copy production environment file to .env
cp .env.production .env

echo "✅ Production environment activated!"
echo ""
echo "🚀 Configuration:"
echo "   - Environment: production"
echo "   - Mock data: disabled"
echo "   - OpenAI API: enabled"
echo "   - Location context: enabled"
echo ""
echo "💡 To test location context, try messages like:"
echo "   - 'Tell me about Borough Market'"
echo "   - 'I'm at Southwark Cathedral'"
echo "   - 'What's interesting about lat: 51.5013, lng: -0.093'"
echo ""
echo "🔙 To switch back to mock mode, run:"
echo "   ./switch_to_mock.sh"

# Make sure the script is executable
chmod +x switch_to_production.sh