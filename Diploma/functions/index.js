const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

// Инициализация Firebase Admin
admin.initializeApp();

// Конфигурация транспорта для отправки email
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASSWORD
    }
});

// Функция для отправки кода верификации
exports.sendVerificationCode = onCall({
    region: 'europe-west1',
    maxInstances: 10
}, async (request) => {
    const { data } = request;
    
    // Проверка входных данных
    if (!data.email || !data.code || !data.username) {
        throw new Error('Отсутствуют необходимые параметры');
    }

    const { email, code, username } = data;

    try {
        // Формируем письмо
        const mailOptions = {
            from: process.env.EMAIL_USER,
            to: email,
            subject: 'Код подтверждения EasyMeal',
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <h2>Здравствуйте, ${username}!</h2>
                    <p>Спасибо за регистрацию в EasyMeal. Для подтверждения вашего email используйте следующий код:</p>
                    <h1 style="text-align: center; font-size: 36px; padding: 20px; background-color: #f5f5f5; border-radius: 10px;">${code}</h1>
                    <p>Если вы не запрашивали этот код, просто проигнорируйте это письмо.</p>
                    <p>С уважением,<br>Команда EasyMeal</p>
                </div>
            `
        };

        // Отправляем письмо
        await transporter.sendMail(mailOptions);
        
        console.log(`Код верификации отправлен на ${email}`);
        return { success: true };
    } catch (error) {
        console.error('Ошибка при отправке email:', error);
        throw new Error('Ошибка отправки email');
    }
}); 