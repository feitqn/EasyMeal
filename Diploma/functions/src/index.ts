import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as nodemailer from 'nodemailer';

admin.initializeApp();

interface VerificationData {
    email: string;
    code: string;
}

// Настройка транспорта для отправки email
const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 587,
    secure: false,
    auth: {
        user: functions.config().gmail.email,
        pass: functions.config().gmail.password
    },
    tls: {
        rejectUnauthorized: false
    }
});

export const sendVerificationEmail = functions.https.onCall(async (data: VerificationData, context: functions.https.CallableContext) => {
    console.log('Получен запрос на отправку email:', data);
    
    const { email, code } = data;
    
    if (!email || !code) {
        console.error('Отсутствует email или код');
        throw new functions.https.HttpsError('invalid-argument', 'Email and code are required');
    }

    const mailOptions = {
        from: `"EasyMeal" <${functions.config().gmail.email}>`,
        to: email,
        subject: 'Verify your email for EasyMeal',
        html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <h2>Welcome to EasyMeal!</h2>
                <p>Your verification code is:</p>
                <h1 style="color: #4CAF50; text-align: center; padding: 20px; background: #f5f5f5; border-radius: 8px;">
                    ${code}
                </h1>
                <p>This code will expire in 10 minutes.</p>
                <p>If you didn't request this code, please ignore this email.</p>
            </div>
        `
    };

    try {
        console.log('Отправка email на адрес:', email);
        await transporter.sendMail(mailOptions);
        console.log('Email успешно отправлен на:', email);
        return { success: true };
    } catch (error) {
        console.error('Ошибка отправки email:', error);
        throw new functions.https.HttpsError('internal', `Error sending email: ${error}`);
    }
});

// Функция для очистки устаревших кодов
export const cleanupOldCodes = functions.pubsub
    .schedule('every 10 minutes')
    .onRun(async (context: functions.EventContext) => {
        const tenMinutesAgo = admin.firestore.Timestamp.fromDate(
            new Date(Date.now() - 10 * 60 * 1000)
        );

        const snapshot = await admin.firestore()
            .collection('verificationCodes')
            .where('createdAt', '<', tenMinutesAgo)
            .get();

        const batch = admin.firestore().batch();
        snapshot.docs.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
            batch.delete(doc.ref);
        });

        await batch.commit();
        console.log('Очищено устаревших кодов:', snapshot.docs.length);
        return null;
    }); 