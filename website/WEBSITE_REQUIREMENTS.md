# MirrorMate Website Requirements for App Store

## 🎯 Overview
Your website at `https://mirrormate.vercel.app` needs to include specific pages and information to comply with Apple's App Store requirements.

---

## 📄 Required Pages

### 1. **Privacy Policy** (`/privacy`)
✅ **CREATED**: Use the `privacy.html` file provided

**Required Elements:**
- Clear description of data collection practices
- How user data is used and shared
- Data retention policies
- User rights (access, deletion, export)
- Third-party services disclosure
- Contact information for privacy inquiries
- GDPR compliance (for EU users)
- Children's privacy (COPPA compliance)

**Apple Requirements:**
- Must be publicly accessible URL
- Must be easily readable
- Must be up-to-date
- Required in App Store Connect

---

### 2. **Terms of Service** (`/terms`)
✅ **CREATED**: Use the `terms.html` file provided

**Required Elements:**
- User account terms
- Acceptable use policy
- Subscription terms and pricing
- Refund policy
- Content ownership and licensing
- Limitation of liability
- Dispute resolution
- Contact information

**Apple Requirements:**
- Must clearly state subscription terms
- Must explain auto-renewal
- Must specify refund policy
- Required for apps with subscriptions

---

### 3. **Homepage** (`/`)
🔨 **TO CREATE**

**Required Elements:**
- App name and logo
- Brief description (1-2 sentences)
- Key features (3-5 bullet points)
- App Store download badge
- Screenshots or demo video
- Links to Privacy Policy & Terms
- Contact information

**Example Structure:**
```html
<header>
  <nav>
    <a href="/">Home</a>
    <a href="/privacy">Privacy</a>
    <a href="/terms">Terms</a>
    <a href="/contact">Contact</a>
  </nav>
</header>

<section class="hero">
  <h1>MirrorMate</h1>
  <p>AI-Powered Communication Coaching</p>
  <a href="[App Store Link]">
    <img src="app-store-badge.svg" alt="Download on App Store">
  </a>
</section>

<section class="features">
  <h2>Features</h2>
  <ul>
    <li>🎥 Video Analysis - Record and analyze your presentations</li>
    <li>🧠 AI Insights - Get detailed feedback on communication</li>
    <li>📊 Progress Tracking - Monitor improvement over time</li>
    <li>💡 Practice Exercises - Personalized coaching tips</li>
  </ul>
</section>

<section class="screenshots">
  <h2>Screenshots</h2>
  <!-- Add 3-5 app screenshots -->
</section>

<footer>
  <p>&copy; 2025 MirrorMate. All rights reserved.</p>
  <a href="/privacy">Privacy Policy</a> | 
  <a href="/terms">Terms of Service</a> | 
  <a href="/contact">Contact</a>
</footer>
```

---

### 4. **Contact Page** (`/contact`)
🔨 **TO CREATE**

**Required Elements:**
- Support email: `support@mirrormate.app`
- Privacy email: `privacy@mirrormate.app`
- Legal email: `legal@mirrormate.app`
- Business email: `business@mirrormate.app`
- Response time expectation
- Optional: Contact form

**Example Structure:**
```html
<section class="contact">
  <h1>Contact Us</h1>
  
  <div class="contact-card">
    <h3>General Support</h3>
    <p><strong>Email:</strong> support@mirrormate.app</p>
    <p><strong>Response Time:</strong> 24-48 hours</p>
  </div>

  <div class="contact-card">
    <h3>Privacy Inquiries</h3>
    <p><strong>Email:</strong> privacy@mirrormate.app</p>
    <p><strong>Response Time:</strong> 48 hours</p>
  </div>

  <div class="contact-card">
    <h3>Legal Matters</h3>
    <p><strong>Email:</strong> legal@mirrormate.app</p>
  </div>

  <div class="contact-card">
    <h3>Business Partnerships</h3>
    <p><strong>Email:</strong> business@mirrormate.app</p>
  </div>
</section>
```

---

### 5. **Support/FAQ Page** (`/support` or `/faq`)
🔨 **OPTIONAL BUT RECOMMENDED**

**Common Questions:**
- How do I cancel my subscription?
- How do I delete my account and data?
- What happens to my videos?
- Is my data secure?
- How accurate is the AI analysis?
- What devices are supported?
- How do I contact support?

---

## 🔗 URL Structure

Your website should have these URLs accessible:

```
https://mirrormate.vercel.app/              → Homepage
https://mirrormate.vercel.app/privacy       → Privacy Policy ✅
https://mirrormate.vercel.app/terms         → Terms of Service ✅
https://mirrormate.vercel.app/contact       → Contact Page
https://mirrormate.vercel.app/support       → Support/FAQ (optional)
```

---

## 📧 Email Setup

You need to set up these email addresses:

1. **support@mirrormate.app** - General customer support
2. **privacy@mirrormate.app** - Privacy inquiries and data requests
3. **legal@mirrormate.app** - Legal matters and ToS questions
4. **business@mirrormate.app** - Business partnerships (optional)
5. **dpo@mirrormate.app** - Data Protection Officer (GDPR)

**How to Set Up:**
- Use a custom domain email service (Google Workspace, Zoho Mail, etc.)
- Or use email forwarding to your personal email
- Ensure you can respond within stated timeframes (24-48 hours)

---

## 🍎 Apple App Store Connect Requirements

When submitting to App Store Connect, you'll need to provide:

### App Information Section:
1. **Privacy Policy URL**
   ```
   https://mirrormate.vercel.app/privacy
   ```

2. **Terms of Use URL** (for subscription apps)
   ```
   https://mirrormate.vercel.app/terms
   ```

3. **Support URL**
   ```
   https://mirrormate.vercel.app/contact
   ```

4. **Marketing URL** (optional)
   ```
   https://mirrormate.vercel.app
   ```

### App Privacy Section:
You'll need to disclose:
- ✅ Data types collected (email, videos, analytics)
- ✅ How data is used (AI analysis, app improvement)
- ✅ Whether data is linked to user identity
- ✅ Whether data is used for tracking
- ✅ Third-party services (Supabase, Stripe, Google AI, Sentry, PostHog)

---

## 🎨 Website Assets Needed

### 1. **App Store Badge**
Download from: https://developer.apple.com/app-store/marketing/guidelines/#downloadOnAppstore

### 2. **App Icon**
- High-resolution PNG (1024x1024)
- Display prominently on homepage

### 3. **Screenshots**
- 3-5 iPhone screenshots showing key features
- Optimized for web (compressed, WebP format)

### 4. **Demo Video** (Optional)
- 30-60 second app walkthrough
- Hosted on YouTube/Vimeo or self-hosted

---

## 🚀 Deployment Checklist

### Before Going Live:
- [ ] All pages are accessible via HTTPS
- [ ] Privacy Policy is complete and accurate
- [ ] Terms of Service includes subscription details
- [ ] Contact emails are set up and monitored
- [ ] App Store badge links to your app (when published)
- [ ] Mobile-responsive design
- [ ] Fast loading times (< 3 seconds)
- [ ] No broken links
- [ ] Legal review (recommended)

### Vercel Deployment:
1. Create a new Vercel project
2. Upload your HTML files:
   ```
   /public/
     ├── index.html          (homepage)
     ├── privacy.html        ✅ provided
     ├── terms.html          ✅ provided
     ├── contact.html        (create)
     └── support.html        (optional)
   ```
3. Configure custom routes in `vercel.json`:
   ```json
   {
     "routes": [
       { "src": "/privacy", "dest": "/privacy.html" },
       { "src": "/terms", "dest": "/terms.html" },
       { "src": "/contact", "dest": "/contact.html" }
     ]
   }
   ```
4. Deploy and test all URLs

---

## 📱 In-App Requirements

Your iOS app should link to these pages:

### In Settings/Profile:
- "Privacy Policy" button → Opens `https://mirrormate.vercel.app/privacy`
- "Terms of Service" button → Opens `https://mirrormate.vercel.app/terms`
- "Contact Support" button → Opens `https://mirrormate.vercel.app/contact`

### Example Swift Code:
```swift
Button("Privacy Policy") {
    if let url = URL(string: "https://mirrormate.vercel.app/privacy") {
        UIApplication.shared.open(url)
    }
}

Button("Terms of Service") {
    if let url = URL(string: "https://mirrormate.vercel.app/terms") {
        UIApplication.shared.open(url)
    }
}

Button("Contact Support") {
    if let url = URL(string: "https://mirrormate.vercel.app/contact") {
        UIApplication.shared.open(url)
    }
}
```

---

## ✅ Final Checklist

**Website:**
- [x] Privacy Policy page created and live
- [x] Terms of Service page created and live
- [ ] Homepage with app description
- [ ] Contact page with all email addresses
- [ ] Support/FAQ page (optional)
- [ ] Mobile-responsive design
- [ ] HTTPS enabled
- [ ] App Store badge with link

**Email:**
- [ ] support@mirrormate.app configured
- [ ] privacy@mirrormate.app configured
- [ ] legal@mirrormate.app configured
- [ ] dpo@mirrormate.app configured
- [ ] Auto-responder set up (optional)

**App Store Connect:**
- [ ] Privacy Policy URL entered
- [ ] Terms of Use URL entered
- [ ] Support URL entered
- [ ] App Privacy details completed
- [ ] All disclosures accurate

**iOS App:**
- [ ] Links to Privacy Policy added
- [ ] Links to Terms of Service added
- [ ] Links to Contact/Support added
- [ ] Deep linking configured

---

## 📞 Support Response Templates

### Template 1: General Support
```
Subject: Re: [User's Subject]

Hi [Name],

Thank you for contacting MirrorMate support. 

[Personalized response to their question]

If you need further assistance, please don't hesitate to reach out.

Best regards,
The MirrorMate Team
support@mirrormate.app
```

### Template 2: Privacy/Data Request
```
Subject: Re: Privacy Inquiry - [Request Type]

Hi [Name],

Thank you for your privacy inquiry. We take data protection seriously.

[Handle request: data export, deletion, or inquiry]

Your request will be processed within [timeframe].

If you have additional questions, please contact privacy@mirrormate.app.

Best regards,
MirrorMate Privacy Team
privacy@mirrormate.app
```

---

## 🔒 Legal Compliance Notes

### GDPR (EU Users):
- ✅ Right to access data
- ✅ Right to deletion
- ✅ Right to data portability
- ✅ Right to object to processing
- ✅ Data Protection Officer contact

### CCPA (California Users):
- ✅ Right to know what data is collected
- ✅ Right to delete data
- ✅ Right to opt-out of data sales (not applicable - we don't sell data)

### COPPA (Children's Privacy):
- ✅ App is 13+ (stated in Terms)
- ✅ No knowingly collecting data from children under 13

---

## 📝 Next Steps

1. **Create Homepage** (`index.html`)
2. **Create Contact Page** (`contact.html`)
3. **Set up email addresses** (support@, privacy@, legal@, dpo@)
4. **Deploy to Vercel** with custom routing
5. **Test all URLs** and email addresses
6. **Update iOS app** with website links
7. **Submit to App Store** with website URLs

---

**Need help with any of these steps? Contact me!**

Good luck with your App Store submission! 🚀

