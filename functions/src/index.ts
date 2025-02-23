import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as nodemailer from 'nodemailer';
import { Request, Response } from 'express';

admin.initializeApp();

// Настройка транспорта для отправки email через Gmail
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: 'bekzatratbek03@gmail.com',
        pass: 'heapsylwpzohucmo'
    }
});

// Функция отправки email
export const sendVerificationEmail = functions.https.onRequest(async (request: Request, response: Response) => {
    try {
        const { email, code } = request.body.data;
        
        console.log('Начало отправки email:', { email, code });

        if (!email || !code) {
            console.error('Отсутствует email или код');
            response.status(400).json({ 
                error: 'Email and code are required' 
            });
            return;
        }

        const mailOptions = {
            from: 'EasyMeal <bekzatratbek03@gmail.com>',
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

        console.log('Отправка email на адрес:', email);
        await transporter.sendMail(mailOptions);
        console.log('Email успешно отправлен на:', email);
        
        response.json({ success: true });
    } catch (error) {
        console.error('Ошибка отправки email:', error);
        response.status(500).json({ 
            error: `Error sending email: ${error}` 
        });
    }
});

// Функция удаления всех пользователей
export const deleteAllUsers = functions.https.onRequest(async (request: Request, response: Response) => {
    try {
        console.log('Начало процесса удаления пользователей');
        
        // Удаление пользователей из Authentication
        const listUsersResult = await admin.auth().listUsers();
        for (const userRecord of listUsersResult.users) {
            await admin.auth().deleteUser(userRecord.uid);
        }
        console.log(`Удалено ${listUsersResult.users.length} пользователей из Authentication`);
        
        // Удаление пользователей из Firestore
        const usersSnapshot = await admin.firestore().collection('users').get();
        const batch = admin.firestore().batch();
        
        usersSnapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
        });
        
        await batch.commit();
        console.log(`Удалено ${usersSnapshot.size} пользователей из Firestore`);
        
        // Удаление верификационных кодов
        const codesSnapshot = await admin.firestore().collection('verificationCodes').get();
        const codesBatch = admin.firestore().batch();
        
        codesSnapshot.docs.forEach((doc) => {
            codesBatch.delete(doc.ref);
        });
        
        await codesBatch.commit();
        console.log(`Удалено ${codesSnapshot.size} верификационных кодов`);
        
        response.json({ 
            success: true, 
            deletedAuthUsers: listUsersResult.users.length,
            deletedFirestoreUsers: usersSnapshot.size,
            deletedCodes: codesSnapshot.size
        });
    } catch (error) {
        console.error('Ошибка при удалении пользователей:', error);
        response.status(500).json({ 
            error: `Ошибка при удалении пользователей: ${error}` 
        });
    }
});
