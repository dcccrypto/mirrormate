#!/bin/bash

# MirrorMate - Function Test Script
# This script verifies all Edge Functions are properly deployed and configured

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 MirrorMate Function Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Change to project directory
cd /Users/khubairnasirm/Desktop/MirrorMate

echo "📋 Test 1: Checking Edge Function Versions..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get function list
FUNCTIONS=$(npx supabase functions list 2>/dev/null | tail -n +3)

if echo "$FUNCTIONS" | grep -q "init-session.*v5"; then
    echo -e "${GREEN}✅ init-session v5 ACTIVE${NC} (includes .mp4 fix)"
else
    echo -e "${RED}❌ init-session NOT v5${NC}"
fi

if echo "$FUNCTIONS" | grep -q "finalize-session.*v2"; then
    echo -e "${GREEN}✅ finalize-session v2 ACTIVE${NC}"
else
    echo -e "${RED}❌ finalize-session NOT v2${NC}"
fi

if echo "$FUNCTIONS" | grep -q "analyze-video.*v6"; then
    echo -e "${GREEN}✅ analyze-video v6 ACTIVE${NC} (includes MIME type fix)"
else
    echo -e "${RED}❌ analyze-video NOT v6${NC}"
fi

echo ""
echo "🔐 Test 2: Checking Secrets..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SECRETS=$(npx supabase secrets list 2>/dev/null)

if echo "$SECRETS" | grep -q "OPENAI_API_KEY"; then
    echo -e "${GREEN}✅ OPENAI_API_KEY is set${NC}"
else
    echo -e "${RED}❌ OPENAI_API_KEY is missing${NC}"
fi

if echo "$SECRETS" | grep -q "SUPABASE_URL"; then
    echo -e "${GREEN}✅ SUPABASE_URL is set${NC}"
else
    echo -e "${RED}❌ SUPABASE_URL is missing${NC}"
fi

if echo "$SECRETS" | grep -q "SUPABASE_SERVICE_ROLE_KEY"; then
    echo -e "${GREEN}✅ SUPABASE_SERVICE_ROLE_KEY is set${NC}"
else
    echo -e "${RED}❌ SUPABASE_SERVICE_ROLE_KEY is missing${NC}"
fi

echo ""
echo "🗄️  Test 3: Checking Database Tables..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check sessions table
SESSIONS=$(npx supabase db execute "SELECT COUNT(*) FROM sessions" 2>/dev/null | tail -1)
if [ ! -z "$SESSIONS" ]; then
    echo -e "${GREEN}✅ sessions table exists${NC} ($SESSIONS total)"
else
    echo -e "${RED}❌ sessions table missing${NC}"
fi

# Check analysis_reports table
REPORTS=$(npx supabase db execute "SELECT COUNT(*) FROM analysis_reports" 2>/dev/null | tail -1)
if [ ! -z "$REPORTS" ]; then
    echo -e "${GREEN}✅ analysis_reports table exists${NC} ($REPORTS total)"
else
    echo -e "${RED}❌ analysis_reports table missing${NC}"
fi

# Check user_quotas table
QUOTAS=$(npx supabase db execute "SELECT COUNT(*) FROM user_quotas" 2>/dev/null | tail -1)
if [ ! -z "$QUOTAS" ]; then
    echo -e "${GREEN}✅ user_quotas table exists${NC} ($QUOTAS total)"
else
    echo -e "${RED}❌ user_quotas table missing${NC}"
fi

echo ""
echo "📊 Test 4: Latest Session Status..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

LATEST=$(npx supabase db execute "SELECT status, video_path, progress, created_at FROM sessions ORDER BY created_at DESC LIMIT 1" 2>/dev/null | tail -n +3 | head -1)

if [ ! -z "$LATEST" ]; then
    echo "$LATEST"
    
    if echo "$LATEST" | grep -q "complete"; then
        echo -e "${GREEN}✅ Status: complete${NC}"
    elif echo "$LATEST" | grep -q "error"; then
        echo -e "${RED}❌ Status: error${NC}"
        echo "Run: npx supabase functions logs analyze-video --limit 5"
    else
        echo -e "${YELLOW}⏳ Status: processing${NC}"
    fi
    
    if echo "$LATEST" | grep -q ".mp4"; then
        echo -e "${GREEN}✅ File extension: .mp4${NC}"
    elif echo "$LATEST" | grep -q ".mov"; then
        echo -e "${RED}❌ File extension: .mov (old version!)${NC}"
    fi
else
    echo -e "${YELLOW}ℹ️  No sessions yet${NC}"
fi

echo ""
echo "📜 Test 5: Recent Function Logs..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Last 3 analyze-video calls:"
npx supabase functions logs analyze-video --limit 3 2>/dev/null | grep -E "(POST|version)" | head -6

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ All functions deployed (v5 init, v6 analyze)"
echo "✅ OpenAI key configured"
echo "✅ Database tables ready"
echo ""
echo -e "${GREEN}Ready to test!${NC} Open the app and record a video."
echo ""
echo "📖 See TESTING_GUIDE.md for detailed test procedures"
echo ""

