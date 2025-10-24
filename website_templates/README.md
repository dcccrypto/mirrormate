# MirrorMate Legal Documents - Website Templates

## 📋 Overview

This folder contains professionally designed HTML templates for your Privacy Policy and Terms of Service that are **required for Apple App Store submission**.

## 📁 Files Included

1. **`privacy-policy.html`** - Privacy Policy webpage
2. **`terms-of-service.html`** - Terms of Service webpage
3. **`README.md`** - This file

## ⚠️ IMPORTANT: You MUST Publish These Before App Store Submission

Apple **requires** that your Privacy Policy and Terms of Service be:
- ✅ Published on a **publicly accessible website**
- ✅ Accessible **without login or authentication**
- ✅ Mobile-friendly and readable
- ✅ Containing your **actual privacy practices** (not placeholders)

## 🚀 Quick Deployment Options

### Option 1: GitHub Pages (FREE & Easy)

**Perfect for:** Quick deployment, no server needed

1. **Create a GitHub Repository:**
   ```bash
   # Create a new repository on GitHub.com named "mirrormate-legal"
   ```

2. **Upload the HTML files:**
   ```bash
   git init
   git add privacy-policy.html terms-of-service.html
   git commit -m "Add legal documents"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/mirrormate-legal.git
   git push -u origin main
   ```

3. **Enable GitHub Pages:**
   - Go to repository Settings
   - Scroll to "Pages" section
   - Select "main" branch
   - Click "Save"

4. **Your URLs will be:**
   ```
   https://YOUR_USERNAME.github.io/mirrormate-legal/privacy-policy.html
   https://YOUR_USERNAME.github.io/mirrormate-legal/terms-of-service.html
   ```

5. **Update your app with these URLs!**

---

### Option 2: Vercel (FREE & Professional)

**Perfect for:** Professional deployment with custom domain

1. **Install Vercel CLI:**
   ```bash
   npm install -g vercel
   ```

2. **Deploy:**
   ```bash
   cd website_templates
   vercel
   ```

3. **Follow the prompts** and your site will be live!

4. **Your URLs will be:**
   ```
   https://your-project.vercel.app/privacy-policy
   https://your-project.vercel.app/terms-of-service
   ```

---

### Option 3: Netlify (FREE & Simple)

**Perfect for:** Drag-and-drop deployment

1. **Go to [Netlify.com](https://netlify.com)**
2. **Drag and drop** the `website_templates` folder
3. **Your site is live instantly!**

4. **Your URLs will be:**
   ```
   https://random-name.netlify.app/privacy-policy
   https://random-name.netlify.app/terms-of-service
   ```

---

### Option 4: Your Existing Website

**Perfect for:** If you already have a website

1. **Upload the HTML files** to your web server:
   ```bash
   /privacy-policy.html
   /terms-of-service.html
   ```

2. **Your URLs will be:**
   ```
   https://yourwebsite.com/privacy-policy
   https://yourwebsite.com/terms-of-service
   ```

---

## ✏️ Required Customizations

Before deploying, **you MUST update** these placeholders in both HTML files:

### 1. Website URL
**Find and replace:**
```html
[Your Website URL]
```
**With:**
```html
https://yourwebsite.com
```

### 2. Company Address (Terms of Service)
**Find and replace:**
```html
[Your Company Name]
[Street Address]
[City, State ZIP]
```
**With:**
```html
MirrorMate LLC (or your company name)
123 Main Street
San Francisco, CA 94102
```

### 3. Support Email (Already set to mirrormate.app)
Emails are already configured as:
- `privacy@mirrormate.app`
- `support@mirrormate.app`
- `legal@mirrormate.app`
- `dpo@mirrormate.app`
- `business@mirrormate.app`

**Make sure these email addresses exist and are monitored!**

---

## 📝 How to Edit the HTML Files

### Using a Text Editor:
1. Open the `.html` file in any text editor (VS Code, Sublime, Notepad++)
2. Search for `[Your Website URL]`
3. Replace with your actual website URL
4. Save the file

### Using Find & Replace:
```bash
# Mac/Linux
sed -i '' 's/\[Your Website URL\]/https:\/\/yourwebsite.com/g' privacy-policy.html
sed -i '' 's/\[Your Website URL\]/https:\/\/yourwebsite.com/g' terms-of-service.html

# Linux only
sed -i 's/\[Your Website URL\]/https:\/\/yourwebsite.com/g' privacy-policy.html
sed -i 's/\[Your Website URL\]/https:\/\/yourwebsite.com/g' terms-of-service.html
```

---

## 🔗 After Deployment: Update Your App

### 1. Update Info.plist (if needed)
If you want to add the URLs to your app's Info.plist:
```xml
<key>PrivacyPolicyURL</key>
<string>https://yourwebsite.com/privacy-policy</string>
<key>TermsOfServiceURL</key>
<string>https://yourwebsite.com/terms-of-service</string>
```

### 2. Update App Store Connect
When submitting your app:
1. Go to App Store Connect
2. Navigate to your app > App Information
3. Enter your Privacy Policy URL in the required field:
   ```
   https://yourwebsite.com/privacy-policy
   ```
4. (Optional) Add Terms of Service URL

### 3. Update App Code (if displaying in-app)
If you display these in your app, update the URLs in your code.

---

## ✅ Verification Checklist

Before submitting to App Store, verify:

- [ ] Privacy Policy is published and accessible
- [ ] Terms of Service is published and accessible  
- [ ] URLs work on mobile browsers (iPhone/iPad)
- [ ] No placeholder text remains (`[Your Website URL]`, etc.)
- [ ] All email addresses are valid and monitored
- [ ] Pages load without errors
- [ ] Pages are readable on mobile devices
- [ ] No authentication/login required to view pages
- [ ] HTTPS enabled (most free hosts provide this automatically)

---

## 🎨 Customization Options

The HTML templates are designed to be beautiful out-of-the-box, but you can customize:

### Change Colors:
Edit the CSS in the `<style>` section:
```css
/* Primary gradient */
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);

/* Accent color */
color: #667eea;
```

### Change Font:
```css
font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, ...;
```

### Add Logo:
Add your logo in the header:
```html
<header>
    <img src="your-logo.png" alt="MirrorMate" style="height: 50px; margin-bottom: 20px;">
    <h1>🛡️ Privacy Policy</h1>
    ...
</header>
```

---

## 📱 Testing on Mobile

Before submission, test on actual devices:

### iPhone/iPad:
1. Open Safari
2. Go to your Privacy Policy URL
3. Check:
   - ✅ Text is readable
   - ✅ No horizontal scrolling needed
   - ✅ Buttons/links work
   - ✅ Page loads quickly

### Android (optional):
Test on Chrome to ensure cross-platform compatibility

---

## 🆘 Common Issues & Solutions

### Issue: "Privacy Policy URL not accessible"
**Solution:** 
- Verify the URL works in an incognito/private browser window
- Ensure it's HTTPS, not HTTP
- Check for typos in the URL

### Issue: "Page not mobile-friendly"
**Solution:**
- The provided templates are already mobile-friendly
- Test the viewport meta tag is present:
  ```html
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  ```

### Issue: "Placeholder text still visible"
**Solution:**
- Search for `[` in both HTML files
- Replace all `[Your Website URL]` instances
- Replace all `[Your Company Name]` instances

---

## 📧 Email Setup

You need these email addresses functional:
- `privacy@mirrormate.app` - Privacy inquiries
- `support@mirrormate.app` - General support
- `legal@mirrormate.app` - Legal matters
- `dpo@mirrormate.app` - GDPR Data Protection Officer
- `business@mirrormate.app` - Business inquiries

### Setup Options:

**Option 1: Google Workspace (Recommended)**
- $6/month per user
- Professional email with your domain
- https://workspace.google.com

**Option 2: Zoho Mail (Free for small teams)**
- Free for up to 5 users
- https://www.zoho.com/mail/

**Option 3: Email Forwarding**
- Set up email forwarding to your personal email
- Many domain registrars offer this free

---

## 🚀 Ready to Deploy?

1. **Choose a deployment method** (GitHub Pages recommended for beginners)
2. **Update placeholder text** in both HTML files
3. **Deploy** to your chosen platform
4. **Test** the URLs on mobile and desktop
5. **Update App Store Connect** with your Privacy Policy URL
6. **Submit your app!** 🎉

---

## 📚 Additional Resources

- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Privacy Details on the App Store](https://developer.apple.com/app-store/app-privacy-details/)
- [GitHub Pages Documentation](https://pages.github.com/)
- [Vercel Documentation](https://vercel.com/docs)
- [Netlify Documentation](https://docs.netlify.com/)

---

## 📞 Need Help?

If you encounter issues deploying these documents:

1. Check the deployment platform's documentation
2. Ensure all placeholder text is replaced
3. Test URLs in an incognito browser window
4. Verify HTTPS is enabled

For MirrorMate app-specific questions:
- Email: support@mirrormate.app

---

## ✨ Features of These Templates

- ✅ **Apple-compliant** - Meets all App Store requirements
- ✅ **Mobile-responsive** - Works perfectly on iPhone/iPad
- ✅ **Modern design** - Beautiful gradient header and clean layout
- ✅ **Easy to read** - Clear typography and spacing
- ✅ **GDPR-compliant** - Includes all required EU disclosures
- ✅ **CCPA-compliant** - Includes California privacy rights
- ✅ **COPPA-compliant** - Proper children's privacy section
- ✅ **Comprehensive** - Covers all data collection and usage
- ✅ **Professional** - Polished appearance builds trust

---

**Last Updated:** January 23, 2025  
**Version:** 1.0

Good luck with your App Store submission! 🚀

