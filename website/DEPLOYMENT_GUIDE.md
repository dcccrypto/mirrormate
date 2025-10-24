# 🚀 MirrorMate Website Deployment Guide

## ✅ What We've Created

Your complete website package includes:

```
website/
├── index.html              ✅ Homepage with features and pricing
├── privacy.html            ✅ Privacy Policy (Apple required)
├── terms.html              ✅ Terms of Service (Apple required)
├── contact.html            ✅ Contact page with all emails
├── vercel.json             ✅ Vercel configuration
├── WEBSITE_REQUIREMENTS.md ✅ Detailed requirements guide
└── DEPLOYMENT_GUIDE.md     ✅ This file
```

---

## 📋 Pre-Deployment Checklist

### 1. Set Up Email Addresses

You need to create these email addresses before deploying:

- [ ] **support@mirrormate.app** - General support
- [ ] **privacy@mirrormate.app** - Privacy inquiries
- [ ] **legal@mirrormate.app** - Legal matters
- [ ] **business@mirrormate.app** - Business inquiries
- [ ] **dpo@mirrormate.app** - Data Protection Officer

**Options:**
1. **Google Workspace** ($6/user/month) - Recommended
2. **Zoho Mail** (Free for up to 5 users)
3. **Namecheap Email** ($0.99/month)
4. **Email Forwarding** (Forward all to your personal email)

---

## 🌐 Deploy to Vercel (Recommended)

### Step 1: Prepare Your Repository

1. **Create a new folder** for your website:
   ```bash
   cd /Users/khubairnasirm/Desktop/MirrorMate
   mkdir -p website-deploy
   cp website/*.html website-deploy/
   cp website/vercel.json website-deploy/
   ```

2. **Initialize Git** (if not already):
   ```bash
   cd website-deploy
   git init
   git add .
   git commit -m "Initial commit: MirrorMate website"
   ```

3. **Push to GitHub** (create a new repo first on github.com):
   ```bash
   git remote add origin https://github.com/YOUR-USERNAME/mirrormate-website.git
   git branch -M main
   git push -u origin main
   ```

### Step 2: Deploy to Vercel

1. **Go to** [https://vercel.com](https://vercel.com)
2. **Sign in** with GitHub
3. Click **"Add New Project"**
4. **Import** your GitHub repository
5. **Configure:**
   - Framework Preset: **Other**
   - Root Directory: **./website-deploy** (or leave as root if you pushed only website files)
   - Build Command: Leave empty
   - Output Directory: Leave as `.`
6. Click **"Deploy"**

### Step 3: Configure Custom Domain

1. In Vercel dashboard, go to **Settings → Domains**
2. Add your domain: **mirrormate.vercel.app** (already assigned)
3. If you have a custom domain (e.g., `mirrormate.app`):
   - Add it in Vercel
   - Update DNS records as instructed by Vercel
   - Wait for DNS propagation (can take up to 48 hours)

---

## 🔗 Alternative: Manual Deployment

If you prefer not to use GitHub, you can deploy directly:

### Option 1: Vercel CLI

```bash
# Install Vercel CLI
npm install -g vercel

# Navigate to website folder
cd /Users/khubairnasirm/Desktop/MirrorMate/website

# Deploy
vercel

# Follow the prompts:
# - Link to existing project or create new
# - Confirm settings
# - Deploy!
```

### Option 2: Drag & Drop

1. Go to [https://vercel.com/new](https://vercel.com/new)
2. Scroll to **"Or, deploy a Template"**
3. Click **"Browse all Templates"**
4. Create a new blank project
5. Drag and drop your `website` folder
6. Click **"Deploy"**

---

## ✅ Post-Deployment Verification

After deployment, test these URLs:

- [ ] **Homepage:** `https://mirrormate.vercel.app/`
- [ ] **Privacy:** `https://mirrormate.vercel.app/privacy`
- [ ] **Terms:** `https://mirrormate.vercel.app/terms`
- [ ] **Contact:** `https://mirrormate.vercel.app/contact`

### Test Checklist:

- [ ] All pages load correctly
- [ ] No broken links
- [ ] Mobile responsive (test on phone)
- [ ] All email links work (`mailto:` links)
- [ ] HTTPS is enabled (should be automatic)
- [ ] Privacy Policy is complete
- [ ] Terms of Service is complete
- [ ] Contact information is accurate

---

## 📱 Update Your iOS App

Once deployed, update your iOS app to link to the website:

### 1. Add Privacy Policy Link

Create a new SwiftUI view or update `ProfileView.swift`:

```swift
// In ProfileView.swift
Button(action: {
    if let url = URL(string: "https://mirrormate.vercel.app/privacy") {
        UIApplication.shared.open(url)
    }
}) {
    HStack {
        Image(systemName: "hand.raised.fill")
        Text("Privacy Policy")
        Spacer()
        Image(systemName: "arrow.up.right.square")
    }
}
```

### 2. Add Terms of Service Link

```swift
Button(action: {
    if let url = URL(string: "https://mirrormate.vercel.app/terms") {
        UIApplication.shared.open(url)
    }
}) {
    HStack {
        Image(systemName: "doc.text.fill")
        Text("Terms of Service")
        Spacer()
        Image(systemName: "arrow.up.right.square")
    }
}
```

### 3. Add Support Link

```swift
Button(action: {
    if let url = URL(string: "https://mirrormate.vercel.app/contact") {
        UIApplication.shared.open(url)
    }
}) {
    HStack {
        Image(systemName: "questionmark.circle.fill")
        Text("Contact Support")
        Spacer()
        Image(systemName: "arrow.up.right.square")
    }
}
```

---

## 🍎 App Store Connect Setup

### 1. Log in to App Store Connect

Go to [https://appstoreconnect.apple.com](https://appstoreconnect.apple.com)

### 2. Navigate to Your App

- Click **"My Apps"**
- Select **MirrorMate** (or create new app)

### 3. Fill in App Information

Under **"App Information"** section:

**Privacy Policy URL:**
```
https://mirrormate.vercel.app/privacy
```

**Terms of Use URL:**
```
https://mirrormate.vercel.app/terms
```

**Support URL:**
```
https://mirrormate.vercel.app/contact
```

**Marketing URL (Optional):**
```
https://mirrormate.vercel.app
```

### 4. Fill in App Privacy Details

Under **"App Privacy"** section, you'll need to disclose:

#### Data Types Collected:
- ✅ **Contact Info:** Email Address
- ✅ **User Content:** Photos or Videos, Audio Data
- ✅ **Identifiers:** User ID
- ✅ **Diagnostics:** Crash Data, Performance Data
- ✅ **Usage Data:** Product Interaction

#### For Each Data Type, Specify:
- **Linked to User:** Yes
- **Used for Tracking:** No (unless you enable ad tracking later)
- **Purposes:**
  - App Functionality
  - Analytics
  - Product Personalization
  - Customer Support

#### Third-Party Access:
Disclose these third parties:
- Supabase (Database/Auth)
- Stripe (Payments)
- Google Gemini AI (Video Analysis)
- Sentry (Crash Reporting)
- PostHog (Analytics)

---

## 📧 Email Setup Instructions

### Option 1: Google Workspace (Recommended)

1. Go to [https://workspace.google.com](https://workspace.google.com)
2. Sign up for Google Workspace
3. Verify your domain ownership
4. Create email accounts:
   - support@mirrormate.app
   - privacy@mirrormate.app
   - legal@mirrormate.app
   - business@mirrormate.app
   - dpo@mirrormate.app
5. Set up email forwarding if needed
6. Configure auto-responder (optional)

### Option 2: Zoho Mail (Free)

1. Go to [https://www.zoho.com/mail](https://www.zoho.com/mail)
2. Sign up for free plan (up to 5 users)
3. Add your domain
4. Verify domain ownership via DNS
5. Create email accounts
6. Set up email forwarding

### Option 3: Simple Forwarding

If you just want to forward all emails to your personal email:

1. Go to your domain registrar (Namecheap, GoDaddy, etc.)
2. Find **Email Forwarding** settings
3. Create forwards:
   - support@mirrormate.app → your-email@gmail.com
   - privacy@mirrormate.app → your-email@gmail.com
   - legal@mirrormate.app → your-email@gmail.com
   - business@mirrormate.app → your-email@gmail.com
   - dpo@mirrormate.app → your-email@gmail.com

**Note:** When replying, use "Reply As" to maintain professional appearance.

---

## 🔄 Making Updates

### Update Website Content

1. **Edit HTML files** locally
2. **Test changes** by opening in browser
3. **Deploy updates:**
   - If using GitHub: Push changes and Vercel auto-deploys
   - If using Vercel CLI: Run `vercel --prod`
   - If using drag & drop: Upload new files

### Update Privacy Policy or Terms

1. **Edit the HTML file** (`privacy.html` or `terms.html`)
2. **Update the "Last Updated" date** at the top
3. **Deploy changes**
4. **Notify users** (required by Apple if material changes)

---

## 📊 Analytics (Optional)

Add Google Analytics to track website visitors:

1. Sign up at [https://analytics.google.com](https://analytics.google.com)
2. Create a new property for your website
3. Get your tracking ID (e.g., `G-XXXXXXXXXX`)
4. Add this code before `</head>` in all HTML files:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

---

## 🐛 Troubleshooting

### Issue: Pages show 404

**Solution:** Check `vercel.json` is in the root and properly configured.

### Issue: Styling looks broken

**Solution:** Ensure all CSS is inline in HTML files (already done) or properly linked.

### Issue: Mobile view is weird

**Solution:** Test on actual device, not just browser dev tools. Adjust viewport meta tag if needed.

### Issue: Email links don't work

**Solution:** Ensure `mailto:` links are formatted correctly: `<a href="mailto:support@mirrormate.app">`

---

## ✅ Final Checklist

Before submitting to App Store:

- [ ] Website is live at `https://mirrormate.vercel.app`
- [ ] All 4 pages are accessible (home, privacy, terms, contact)
- [ ] Email addresses are set up and monitored
- [ ] Privacy Policy is complete and accurate
- [ ] Terms of Service includes all subscription details
- [ ] iOS app links to website pages
- [ ] Tested on mobile devices
- [ ] HTTPS is enabled (automatic with Vercel)
- [ ] No broken links or missing content
- [ ] App Store Connect URLs are filled in
- [ ] App Privacy details are complete

---

## 📞 Need Help?

If you encounter issues:

1. Check Vercel deployment logs
2. Verify DNS settings (if using custom domain)
3. Test in incognito/private browsing mode
4. Clear browser cache
5. Check browser console for errors (F12 → Console)

---

## 🎉 You're Ready!

Once everything is deployed and tested, you're ready to submit your app to the App Store!

**Good luck! 🚀**

