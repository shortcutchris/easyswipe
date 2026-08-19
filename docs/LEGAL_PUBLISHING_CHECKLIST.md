# Legal publishing checklist

The website now contains prepared German drafts under `/de`, English pages under `/en` and French pages under `/fr`, including localized imprint, privacy and license routes. The legacy German routes `/impressum`, `/datenschutz` and `/lizenzen` remain available. The legal pages are intentionally marked as incomplete and must not be deployed until the personal fields are confirmed.

## Required operator details

Fill `website/src/siteConfig.js` with:

- the full legal name exactly as used for official correspondence;
- a physical address at which legal documents can be served;
- a public contact email address;
- the competent state data-protection authority for that address;
- if applicable: legal form, representative, commercial register details and VAT identification number.

Confirm whether the project is published privately, as a sole proprietor, or through another legal entity. This determines whether the optional business and consumer-dispute information is needed.

## Technical verification before publication

1. Confirm that the website still has no analytics, advertising, accounts, forms or non-essential cookies.
2. Build the website and run its Sites tests.
3. Open every legal route on desktop and mobile.
4. Check the published response headers and cookies again after deployment. Update the privacy policy if the host or cookie behavior changes.
5. Re-check all download, source, release and license links without being logged into GitHub.

## Maintenance triggers

Review the legal pages whenever hosting, analytics, forms, update hosting, payment features, the operator, the public contact details or the app's data behavior changes.

This checklist and the prepared text reduce obvious omissions but are not a substitute for individual legal advice.
