import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _accent = Color(0xFFE8A399);
const _accentDeep = Color(0xFFD8897E);
const _ink = Color(0xFF3D2F33);

/// Colle ton texte légal ici. Les sauts de ligne sont conservés à l'affichage.
const kTermsAndConditions = '''
**Terms & Conditions**

Article 1 — Publisher Identification

The MelloSnap Application is published by:

MelloSnap Inc.
Registered office: Quebec, Canada
Email: support@mellosnap.com

The Application is available on the Google Play Store and Apple App Store.

---

Article 2 — Description of the Service

MelloSnap is a mobile application that recreates the experience of a digital disposable camera. The service includes:

- The ability for the user to take up to 24 photographs per "roll"
- Photos are locked for the duration of the roll — no photo can be viewed until the roll is complete
- The choice of a print format (Standard 4×6, Polaroid 3×3, Photo Strip) at the end of the roll
- Payment processing and delivery of printed photographs to the postal address provided by the user
- Physical delivery of prints by mail

MelloSnap is a transactional service. No monthly subscription is required. Each order is independent.

---

Article 3 — Access Conditions and Registration

3.1 Minimum Age

Use of MelloSnap is restricted to persons aged 13 or older. Persons aged 13 to 17 must obtain the consent of a parent or legal guardian before using the service.

3.2 Account Creation

Access to the Application requires the creation of an account. Users may register via:

- Email address and password
- Sign in with Google

The user agrees to provide accurate, complete, and up-to-date information when registering. The user is responsible for the confidentiality of their login credentials and all activities carried out from their account.

3.3 Single Account

Each user may only create one personal account. Creating multiple accounts to circumvent restrictions or take advantage of promotional offers is prohibited and may result in the suspension of all accounts involved.

---

Article 4 — How Rolls and Orders Work

4.1 Taking Photos and Locking

Each roll allows exactly 24 photographs to be taken. Once the roll has started:

- Photos taken are not accessible to the user for the duration of the roll
- It is not possible to delete, edit, or filter photos taken
- An incomplete roll (fewer than 24 photos) cannot be ordered

MelloSnap does not guarantee the artistic quality of photographs taken using the Application. Quality depends on lighting conditions, the device used, and other external factors.

4.2 Choosing a Format and Ordering

Upon completion of the roll, the user chooses a print format from:

- Standard 4×6 inches — glossy print
- Polaroid 3×3 inches — glossy print, white border
- Photo Strip — 4 photos in a strip

Additional copies may be ordered at a 20% discount off the unit price of the selected format (maximum 3 copies per order).

4.3 Order Processing

The order is confirmed after payment validation. MelloSnap then transmits the photographs to its print partner Mediaclip for printing and shipping. The user can no longer modify their order after payment is confirmed.

---

Article 5 — Pricing, Payment, and Billing

5.1 Pricing

Prices displayed in the Application are in Canadian dollars (CAD), including applicable taxes (GST 5% + QST 9.975%). Prices in effect at the time of the order are those shown during the payment process.

For reference, base prices are:

- Standard 4×6: 12.99 CAD per roll
- Polaroid 3×3: 15.99 CAD per roll
- Large print: 14.99 CAD per roll

MelloSnap reserves the right to change its prices at any time. Updated prices apply only to orders placed after the effective date of the change.

5.2 Shipping

Standard shipping is included in the base price. No additional shipping fee is charged for standard delivery. An express delivery option may be offered for an additional 6.00 CAD.

5.3 Payment

Payments are securely processed by our payment provider Stripe. MelloSnap accepts:

- Major credit and debit cards (Visa, Mastercard)
- Google Pay

MelloSnap does not store your payment card information. This data is processed directly by Stripe in accordance with PCI-DSS standards.

5.4 Billing

A payment receipt is automatically sent to the email address associated with the user's account after each confirmed order.

---

Article 6 — Delivery and Timelines

6.1 Delivery Zone

MelloSnap delivers within Canada only at the initial launch of the service. Expansion to other countries will be announced in the Application.

6.2 Delivery Timelines

Estimated delivery times are:

- Standard delivery: 7 to 10 business days after order confirmation
- Express delivery (if available): 2 to 3 business days

These timelines are provided as estimates. MelloSnap cannot be held responsible for delays caused by external factors (postal strikes, weather conditions, address errors provided by the user, etc.).

6.3 Delivery Address

The user is responsible for the accuracy of the delivery address provided. In the event of an address error resulting in non-delivery or loss of the package, MelloSnap will not be required to reprint or issue a refund, except in the case of proven fault on its part.

---

Article 7 — Refund and Return Policy

7.1 Nature of the Product

Photographic prints are personalized products made to order. Under the provisions relating to custom-made goods, these products are not eligible for the standard right of withdrawal provided by consumer protection law.

7.2 Refunds for Defects

MelloSnap accepts refund or reprint requests in the following cases:

- Product damaged upon delivery (photo required within 7 days of receipt)
- Printing error attributable to MelloSnap (incorrect colors, wrong format)
- Non-delivery after 21 business days for standard delivery

To submit a claim, the user must contact support@mellosnap.com within the indicated timeframes, with proof of order and photos of the defect where applicable.

7.3 Exclusions

The following do not give rise to a refund:

- Artistic quality deemed insufficient (blur, poor lighting) — related to the user's photography
- Change of mind after payment confirmation
- Damage caused by improper handling of the package upon receipt

---

Article 8 — Intellectual Property

8.1 MelloSnap's Rights

The Application, its interface, design, algorithms, source code, and trademarks are the exclusive property of MelloSnap Inc. Any unauthorized reproduction, modification, distribution, or commercial use is prohibited.

8.2 Users' Rights Over Their Photos

The user retains full ownership of the photographs they take via the Application. MelloSnap does not acquire any rights over the user's photographic content, except for rights strictly necessary to provide the service (temporary storage, processing for printing).

8.3 License Granted to MelloSnap

By using the service, the user grants MelloSnap a non-exclusive, worldwide, royalty-free, and revocable license to:

- Store photographs on our secure servers (Supabase) for printing purposes
- Transmit photographs to our print partner (Mediaclip) solely for production purposes
- Delete photographs from our servers within 30 days of confirmed delivery

MelloSnap does not sell, rent, or share users' photographs for commercial or advertising purposes.

---

Article 9 — Personal Data Protection

9.1 Data Collected

MelloSnap collects the following data:

- Identification information: name, email address
- Delivery address: street, city, province, postal code, country
- Payment data: processed exclusively by Stripe (not stored by MelloSnap)
- Photographs: stored temporarily for printing, deleted after delivery
- Usage data: order history, account creation date

9.2 Purposes of Processing

Data is used to:

- Create and manage your user account
- Process your orders and coordinate delivery
- Send you order confirmations and payment receipts
- Improve the service and prevent fraud
- Comply with our legal obligations

9.3 Legal Basis

The processing of your personal data is based on: contract performance (order processing), your consent (marketing communications), and our legal obligations.

9.4 Retention

Account data is retained for the duration of your registration and up to 3 years after account closure. Photographs are deleted within 30 days of delivery. Billing data is retained for 7 years in accordance with tax obligations.

9.5 Your Rights

In accordance with Law 25 (Quebec) and applicable data protection laws, you have the following rights:

- Right of access to your personal data
- Right to rectification of inaccurate data
- Right to erasure ("right to be forgotten")
- Right to data portability
- Right to withdraw your consent at any time

To exercise these rights, contact our data protection officer at: privacy@mellosnap.com

9.6 Third-Party Partners

MelloSnap uses the following partners to provide the service:

- Supabase Inc. — database and storage hosting (servers in North America)
- Stripe Inc. — payment processing
- Mediaclip — printing and order fulfillment

Each of these partners is subject to contractual confidentiality and security obligations.

---

Article 10 — Account Deletion

The user may delete their account at any time from the Application settings (Account → Delete my account). Account deletion results in:

- Deletion of all personal data within 30 days
- Cancellation of any ongoing roll (non-refundable if currently being processed)
- Retention of billing data for 7 years in accordance with tax obligations

In accordance with Apple App Store and Google Play requirements, account deletion is available directly in the Application without needing to contact support.

---

Article 11 — Liability and Limitations

11.1 MelloSnap's Liability Limitations

MelloSnap undertakes to provide the service with the reasonable care expected of a professional provider. However, MelloSnap cannot be held liable for:

- Indirect, consequential, or immaterial damages (loss of revenue, loss of data, etc.)
- Service interruptions due to external causes (third-party infrastructure failure, force majeure)
- The artistic quality of photographs related to the user's photography
- Delivery delays attributable to third-party postal services

11.2 User Responsibility

The user is responsible for:

- The accuracy of information provided during registration and orders
- The content of photographs taken via the Application
- The security of their login credentials
- Compliance with these Terms and applicable laws

11.3 Prohibited Content

It is strictly prohibited to use MelloSnap to take or order prints of photographs:

- Of a sexual nature involving minors
- Infringing on the image rights or privacy of third parties without their consent
- Of a hateful, discriminatory, or violence-inciting nature
- Violating the copyright or intellectual property rights of third parties

MelloSnap reserves the right to refuse to print any content contrary to these provisions and to suspend the relevant account without refund.

---

Article 12 — Modifications to the Service and Terms

12.1 Service Modifications

MelloSnap reserves the right to modify, suspend, or discontinue all or part of the service at any time, with or without notice. In the event of permanent discontinuation of the service, pending orders will be refunded.

12.2 Terms Modifications

These Terms may be modified at any time. In the event of a material change, MelloSnap will notify users by email or via a notification in the Application at least 30 days before the changes take effect. Continued use of the service after that date constitutes acceptance of the new Terms.

---

Article 13 — Suspension and Termination

MelloSnap reserves the right to suspend or terminate a user's access without notice and without refund in the event of:

- Violation of these Terms
- Fraudulent use of the service
- Abusive behavior toward customer support
- Attempts to circumvent security systems

In the event of unjustified suspension, the user may contact support@mellosnap.com to contest the decision.

---

Article 14 — Governing Law and Dispute Resolution

14.1 Governing Law

These Terms are governed by the law of the province of Quebec (Canada) and applicable Canadian federal laws, including in particular the Consumer Protection Act (CPA) and Law 25 on the protection of personal information.

14.2 Amicable Resolution

In the event of a dispute relating to the use of the service, the user is invited to contact MelloSnap first at support@mellosnap.com. MelloSnap undertakes to respond within 5 business days and to seek an amicable solution.

14.3 Competent Jurisdiction

Failing amicable resolution, any dispute will be subject to the exclusive jurisdiction of the courts of the province of Quebec, Canada.

14.4 Quebec Consumer Protection

Nothing in these Terms is intended to limit the rights enjoyed by Quebec consumers under the Quebec Consumer Protection Act.

---

Article 15 — Miscellaneous Provisions

15.1 Entire Agreement

These Terms, along with the Privacy Policy and any order agreement concluded through the Application, constitute the entire agreement between the user and MelloSnap regarding use of the service.

15.2 Severability

If any provision of these Terms is found to be invalid or unenforceable, the remaining provisions will remain in effect.

15.3 No Waiver

MelloSnap's failure to exercise any right provided for in these Terms does not constitute a waiver of that right.

15.4 Assignment

The user may not assign their rights or obligations under these Terms without MelloSnap's prior written consent. MelloSnap may assign its rights and obligations to a third party (including in the event of acquisition by another company) subject to notifying users.

---

Article 16 — Contact and Customer Service

For any questions, complaints, or requests relating to these Terms or the use of the Application:

MelloSnap Inc.
Email: alekmediaclip@gmail.com
Response time: 2 to 5 business days

For questions relating to personal data protection:
Email: alekmediaclip@gmail.com

MelloSnap Inc. — Terms & Conditions v1.0 — July 2026
''';

/// Affiche les conditions d'utilisation en lecture seule, style Settings.
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _TermsBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Terms & Conditions',
                          style: GoogleFonts.lora(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      child: SelectableText(
                        kTermsAndConditions.trim(),
                        style: GoogleFonts.lora(
                          fontSize: 15,
                          height: 1.6,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsBackground extends StatelessWidget {
  const _TermsBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF9F6),
            Color(0xFFF7EDE8),
            Color(0xFFF3F1F1),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withValues(alpha: 0.25),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.25),
                    blurRadius: 80,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.75),
      shape: const CircleBorder(side: BorderSide(color: Colors.white)),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: _accentDeep, size: 22),
        ),
      ),
    );
  }
}
