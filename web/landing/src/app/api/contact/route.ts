import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    const body = await request.json();

    // Validate required fields
    const { name, email, company, phone, message } = body;

    if (!name || !email || !message) {
      return NextResponse.json(
        { error: 'Name, email, and message are required' },
        { status: 400 }
      );
    }

    // Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return NextResponse.json(
        { error: 'Invalid email format' },
        { status: 400 }
      );
    }

    // TODO: Integrate with email service (SendGrid, AWS SES, etc.)
    // For now, just log the contact request
    console.log('Contact form submission:', {
      name,
      email,
      company,
      phone,
      message,
      timestamp: new Date().toISOString(),
    });

    // In production, you would:
    // 1. Save to database
    // 2. Send email notification to sales team
    // 3. Send auto-reply to customer
    // 4. Add to CRM (HubSpot, Salesforce, etc.)

    return NextResponse.json(
      {
        success: true,
        message: 'Thank you for your interest! We will contact you soon.'
      },
      { status: 200 }
    );
  } catch (error) {
    console.error('Contact form error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
