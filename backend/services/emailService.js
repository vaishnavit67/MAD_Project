const nodemailer = require('nodemailer');

// Configure transporter
let transporter = null;

function getTransporter() {
  if (transporter) return transporter;

  const host = process.env.SMTP_HOST;
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  const port = parseInt(process.env.SMTP_PORT || '587', 10);

  if (host && user && pass) {
    try {
      transporter = nodemailer.createTransport({
        host,
        port,
        secure: port === 465,
        auth: { user, pass },
      });
      console.log('[EmailService]: SMTP transporter initialized with host: ' + host);
    } catch (e) {
      console.warn('[EmailService Warning]: Failed to initialize SMTP transporter:', e.message);
    }
  }

  // Fallback to test/console logger if no SMTP configured
  if (!transporter) {
    transporter = {
      sendMail: async (options) => {
        console.log('\n======================================================');
        console.log('[EmailService Mock Delivery]');
        console.log('To:      ', options.to);
        console.log('Subject: ', options.subject);
        console.log('From:    ', options.from || process.env.SMTP_FROM || 'noreply@campusconnect.amrita.edu');
        console.log('Text:    ', (options.text || '').trim().slice(0, 150) + '...');
        console.log('======================================================\n');
        return { messageId: 'mock-email-' + Date.now(), accepted: [options.to] };
      },
    };
  }

  return transporter;
}

const DEFAULT_FROM = process.env.SMTP_FROM || '"Campus Connect" <noreply@campusconnect.amrita.edu>';

/**
 * Send an email safely without crashing the caller
 */
async function sendSafeMail(mailOptions) {
  try {
    const t = getTransporter();
    const result = await t.sendMail({
      from: mailOptions.from || DEFAULT_FROM,
      ...mailOptions,
    });
    return { success: true, result };
  } catch (err) {
    console.error('[EmailService Error]: Could not deliver email to ' + mailOptions.to + ':', err.message);
    return { success: false, error: err.message };
  }
}

/**
 * 1. Sent to Faculty Lead when a student submits a join request
 */
async function sendClubJoinRequestToTeacher({
  teacherEmail,
  teacherName,
  studentName,
  studentEmail,
  studentRoll,
  clubName,
}) {
  if (!teacherEmail) return { success: false, error: 'No teacher email provided' };

  const subject = `[Campus Connect] New Club Join Request: ${studentName} for ${clubName}`;
  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e2e8f0; borderRadius: 12px;">
      <h2 style="color: #4f46e5; margin-top: 0;">Campus Connect • Club Membership Request</h2>
      <p>Hello <strong>${teacherName || 'Faculty Coordinator'}</strong>,</p>
      <p>A student has submitted a formal request to join your club, <strong>${clubName}</strong>.</p>
      <div style="background-color: #f8fafc; padding: 16px; border-radius: 8px; margin: 16px 0;">
        <p style="margin: 4px 0;"><strong>Student Name:</strong> ${studentName}</p>
        <p style="margin: 4px 0;"><strong>Student Email:</strong> ${studentEmail}</p>
        ${studentRoll ? `<p style="margin: 4px 0;"><strong>Roll Number:</strong> ${studentRoll}</p>` : ''}
        <p style="margin: 4px 0;"><strong>Club:</strong> ${clubName}</p>
        <p style="margin: 4px 0;"><strong>Requested At:</strong> ${new Date().toLocaleString('en-IN')}</p>
      </div>
      <p>You can review, approve, or decline this request directly inside the <strong>Campus Connect App</strong> under your club management dashboard.</p>
      <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;" />
      <p style="color: #64748b; font-size: 12px;">This is an automated notification from Amrita Vishwa Vidyapeetham Campus Connect.</p>
    </div>
  `;

  return sendSafeMail({
    to: teacherEmail,
    subject,
    text: `New Club Join Request: ${studentName} (${studentEmail}) has requested to join ${clubName}. Please review in the Campus Connect app.`,
    html,
  });
}

/**
 * 2. Sent to Student upon submitting a club join request
 */
async function sendClubJoinRequestConfirmationToStudent({
  studentEmail,
  studentName,
  clubName,
  teacherName,
}) {
  if (!studentEmail) return { success: false, error: 'No student email provided' };

  const subject = `[Campus Connect] Join Request Received: ${clubName}`;
  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e2e8f0; borderRadius: 12px;">
      <h2 style="color: #4f46e5; margin-top: 0;">Campus Connect • Request Confirmation</h2>
      <p>Hello <strong>${studentName}</strong>,</p>
      <p>Your request to join <strong>${clubName}</strong> has been successfully submitted and forwarded to the Faculty Coordinator <strong>${teacherName || 'Faculty Lead'}</strong> for review.</p>
      <div style="background-color: #f0fdf4; border-left: 4px solid #22c55e; padding: 12px; margin: 16px 0;">
        <p style="margin: 0; color: #15803d; font-weight: bold;">Status: Pending Faculty Approval</p>
        <p style="margin: 4px 0 0 0; color: #166534; font-size: 13px;">You will receive an email and push notification once your membership is approved.</p>
      </div>
      <p>In the meantime, feel free to browse campus navigation and upcoming open events!</p>
      <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;" />
      <p style="color: #64748b; font-size: 12px;">Campus Connect • Amrita Vishwa Vidyapeetham</p>
    </div>
  `;

  return sendSafeMail({
    to: studentEmail,
    subject,
    text: `Your request to join ${clubName} has been received and is pending faculty approval from ${teacherName || 'Faculty Lead'}.`,
    html,
  });
}

/**
 * 3. Sent to Student when Faculty approves their club join request
 */
async function sendClubJoinApprovalToStudent({
  studentEmail,
  studentName,
  clubName,
  teacherName,
}) {
  if (!studentEmail) return { success: false, error: 'No student email provided' };

  const subject = `[Campus Connect] You're in! Approved for ${clubName} 🎉`;
  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e2e8f0; borderRadius: 12px;">
      <h2 style="color: #10b981; margin-top: 0;">🎉 Membership Approved!</h2>
      <p>Hello <strong>${studentName}</strong>,</p>
      <p>Great news! Your request to join <strong>${clubName}</strong> has been <strong>approved</strong> by Faculty Coordinator <strong>${teacherName || 'Faculty Lead'}</strong>.</p>
      <div style="background-color: #ecfdf5; padding: 16px; border-radius: 8px; margin: 16px 0;">
        <p style="margin: 0; font-weight: bold; color: #065f46;">You are now an active member of ${clubName}!</p>
        <p style="margin: 6px 0 0 0; color: #047857; font-size: 13px;">You will now receive announcements, task updates, and priority invitations to club workshops and events.</p>
      </div>
      <p>Open the Campus Connect app on your mobile device to view club activities and collaborate with fellow members.</p>
      <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;" />
      <p style="color: #64748b; font-size: 12px;">Campus Connect • Amrita Vishwa Vidyapeetham</p>
    </div>
  `;

  return sendSafeMail({
    to: studentEmail,
    subject,
    text: `Congratulations! Your request to join ${clubName} has been approved by ${teacherName || 'Faculty Lead'}. You are now an active member.`,
    html,
  });
}

/**
 * 4. Confirmation sent to user when a Lost or Found item is reported
 */
async function sendLostItemReportConfirmation({
  userEmail,
  userName,
  itemTitle,
  itemType,
  location,
}) {
  if (!userEmail) return { success: false, error: 'No user email provided' };

  const isLost = itemType.toLowerCase() === 'lost';
  const subject = `[Campus Connect] ${isLost ? 'Lost Item Report' : 'Found Item Report'}: ${itemTitle}`;
  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e2e8f0; borderRadius: 12px;">
      <h2 style="color: #4f46e5; margin-top: 0;">Campus Connect • Lost & Found Confirmation</h2>
      <p>Hello <strong>${userName}</strong>,</p>
      <p>Your <strong>${isLost ? 'Lost Item' : 'Found Item'}</strong> listing for <strong>"${itemTitle}"</strong> has been successfully submitted and is now active on the campus bulletin.</p>
      <div style="background-color: #f8fafc; padding: 14px; border-radius: 8px; margin: 16px 0;">
        <p style="margin: 4px 0;"><strong>Item:</strong> ${itemTitle}</p>
        <p style="margin: 4px 0;"><strong>Type:</strong> ${isLost ? 'Reported Lost' : 'Reported Found'}</p>
        <p style="margin: 4px 0;"><strong>Location:</strong> ${location}</p>
        <p style="margin: 4px 0;"><strong>Status:</strong> Active / Search in Progress</p>
      </div>
      <p>You will receive an email and mobile push notification as soon as someone submits a verification claim or provides an update on this item.</p>
      <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;" />
      <p style="color: #64748b; font-size: 12px;">Campus Connect • Student Safety & Campus Services</p>
    </div>
  `;

  return sendSafeMail({
    to: userEmail,
    subject,
    text: `Your ${isLost ? 'lost' : 'found'} report for "${itemTitle}" at ${location} has been registered. You will be notified of updates.`,
    html,
  });
}

/**
 * 5. Sent to item owner when someone submits a claim
 */
async function sendLostItemClaimNotification({
  ownerEmail,
  ownerName,
  claimantName,
  itemTitle,
  claimMessage,
}) {
  if (!ownerEmail) return { success: false, error: 'No owner email provided' };

  const subject = `[Campus Connect] Verification Claim Received for: ${itemTitle}`;
  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e2e8f0; borderRadius: 12px;">
      <h2 style="color: #4f46e5; margin-top: 0;">Campus Connect • Lost & Found Claim</h2>
      <p>Hello <strong>${ownerName}</strong>,</p>
      <p>A campus member (<strong>${claimantName}</strong>) has submitted a verification claim for your listing: <strong>"${itemTitle}"</strong>.</p>
      <div style="background-color: #f8fafc; padding: 14px; border-radius: 8px; margin: 16px 0;">
        <p style="margin: 0; font-weight: bold; color: #334155;">Claim Message / Identification Details:</p>
        <p style="margin: 6px 0 0 0; color: #475569; font-style: italic;">"${claimMessage}"</p>
      </div>
      <p>Please log in to the Campus Connect mobile app to review the claim, verify their proof, and approve or reject it.</p>
      <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;" />
      <p style="color: #64748b; font-size: 12px;">Campus Connect • Student Safety & Campus Services</p>
    </div>
  `;

  return sendSafeMail({
    to: ownerEmail,
    subject,
    text: `A claim was submitted by ${claimantName} for "${itemTitle}". Message: "${claimMessage}". Review in app.`,
    html,
  });
}

/**
 * 6. Sent to claimant when their claim is approved or rejected
 */
async function sendClaimStatusNotification({
  claimantEmail,
  claimantName,
  itemTitle,
  status,
  ownerName,
}) {
  if (!claimantEmail) return { success: false, error: 'No claimant email provided' };

  const isApproved = status.toLowerCase() === 'approved';
  const subject = `[Campus Connect] Claim Update for ${itemTitle}: ${isApproved ? 'APPROVED' : 'DECLINED'}`;
  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e2e8f0; borderRadius: 12px;">
      <h2 style="color: ${isApproved ? '#10b981' : '#ef4444'}; margin-top: 0;">
        ${isApproved ? '✓ Claim Approved!' : 'Claim Status Update'}
      </h2>
      <p>Hello <strong>${claimantName}</strong>,</p>
      <p>Your verification claim for <strong>"${itemTitle}"</strong> has been reviewed by <strong>${ownerName || 'the item reporter'}</strong> and marked as <strong>${status.toUpperCase()}</strong>.</p>
      ${
        isApproved
          ? `<div style="background-color: #ecfdf5; border-left: 4px solid #10b981; padding: 12px; margin: 16px 0;">
               <p style="margin: 0; color: #065f46; font-weight: bold;">Collection Details:</p>
               <p style="margin: 4px 0 0 0; color: #047857; font-size: 13px;">Please coordinate with ${ownerName || 'the poster'} or visit Campus Security Desk to retrieve your item.</p>
             </div>`
          : `<div style="background-color: #fef2f2; border-left: 4px solid #ef4444; padding: 12px; margin: 16px 0;">
               <p style="margin: 0; color: #991b1b; font-size: 13px;">The claim could not be verified with the provided details. If you believe this is an error, please contact Campus Support.</p>
             </div>`
      }
      <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;" />
      <p style="color: #64748b; font-size: 12px;">Campus Connect • Student Safety & Campus Services</p>
    </div>
  `;

  return sendSafeMail({
    to: claimantEmail,
    subject,
    text: `Your claim for "${itemTitle}" was marked as ${status.toUpperCase()} by ${ownerName}.`,
    html,
  });
}

module.exports = {
  sendClubJoinRequestToTeacher,
  sendClubJoinRequestConfirmationToStudent,
  sendClubJoinApprovalToStudent,
  sendLostItemReportConfirmation,
  sendLostItemClaimNotification,
  sendClaimStatusNotification,
};
