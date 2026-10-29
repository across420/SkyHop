# Sending Sky Hop to TestFlight from Windows

iPhone apps can only be built on a Mac, so `push_to_testflight.bat` sends your project to GitHub,
where a free Mac build server builds it and uploads it to Apple. You do the setup below once;
after that, double-click the batch file whenever you want a new TestFlight build.

## One-time setup (about 20 minutes)

### 1. Apple Developer account
Join the Apple Developer Program ($99/year) at https://developer.apple.com/programs/ if you haven't.

### 2. Register the bundle ID
1. https://developer.apple.com/account/resources/identifiers → **+** → **App IDs** → **App**.
2. Description: `Sky Hop`. Bundle ID (Explicit): something like `com.yourname.skyhop`.
3. Under Capabilities tick **Game Center**. Click **Continue → Register**.

### 3. Create the app in App Store Connect
https://appstoreconnect.apple.com → **Apps** → **+** → **New App** → iOS, pick the bundle ID from step 2,
SKU `skyhop001`. (The name must be unique on the App Store; you can change it later.)

### 4. Create an API key (lets the build server sign and upload for you)
1. App Store Connect → **Users and Access** → **Integrations** → **App Store Connect API** → **Team Keys** → **+**.
2. Name: `GitHub`. Access: **Admin** (needed so it can create the signing certificate).
3. Download the `.p8` file (you can only download it once — keep it safe).
4. Note the **Key ID** and the **Issuer ID** shown at the top of that page.

Your **Team ID** is at https://developer.apple.com/account → Membership details.

### 5. Install Git and make a GitHub repository
1. Install Git for Windows: https://git-scm.com/download/win (default options are fine).
2. Create a free GitHub account if needed, then https://github.com/new → name it `skyhop`,
   choose **Private**, and **don't** add a README. Copy the URL it shows.

### 6. Add your secrets to GitHub
In your new repository: **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.
Add these five (names must match exactly):

| Name | Value |
|---|---|
| `APPLE_TEAM_ID` | your 10-character Team ID |
| `BUNDLE_ID` | e.g. `com.yourname.skyhop` (same as step 2) |
| `ASC_KEY_ID` | the Key ID from step 4 |
| `ASC_ISSUER_ID` | the Issuer ID from step 4 |
| `ASC_PRIVATE_KEY` | open the `.p8` file in Notepad and paste **everything**, including the BEGIN/END lines |

## Every time you want a new build

Double-click **`push_to_testflight.bat`** in the SkyHop folder.

- The first time it asks for your name, email and the GitHub repository URL, and a GitHub sign-in window appears.
- It opens the progress page. A green check (about 10–15 minutes) means the build was uploaded.
- Apple then processes it for 5–30 minutes. It appears in App Store Connect → your app → **TestFlight**.
- To test on your phone: install the **TestFlight** app from the App Store, then in App Store Connect →
  TestFlight → **Internal Testing** → add yourself as a tester.

Build numbers go up automatically each time, so you never have to edit them.

## If the build fails

Click the red ✗ on the progress page, open the failing step, and copy the red error lines back to Claude.
Common ones:

- **"Missing GitHub secret"** — a secret name is misspelled or empty (step 6).
- **"No profiles for … were found" / certificate errors** — the API key isn't **Admin**, or the bundle ID secret
  doesn't match the one you registered.
- **"No suitable application records were found"** — the app wasn't created in App Store Connect (step 3) with that bundle ID.

GitHub gives private repositories 2,000 free build minutes a month; Mac minutes count 10×,
so that's roughly 12–15 builds a month for free. Public repositories are unlimited.
