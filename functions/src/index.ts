import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { GoogleGenerativeAI } from "@google/generative-ai";

// API key Firebase Secret Manager'da güvenli şekilde saklanır
const geminiKey = defineSecret("GEMINI_API_KEY");

const SYSTEM_PROMPT = `Sen ALO Halısaha platformunun yardımcı asistanısın.
Adın "ALO Bot". Türkçe konuşuyorsun ve kısa, samimi, yardımsever cevaplar veriyorsun.

Platform hakkında bilgiler:
- ALO Halısaha, Türkiye'nin halı saha rezervasyon ve maç organizasyon platformudur.
- Kullanıcılar sahaya kolayca rezervasyon yapabilir, yakınlarındaki sahaları haritada görebilir.
- "Maç Kur" özelliği ile arkadaşlarını veya yabancıları bir araya getirerek maç organize edebilirler.
- "Gruplar" bölümünde açık maç ilanlarına katılabilirler.
- Profil sayfasında geçmiş rezervasyonlarını ve puanlarını görebilirler.
- Rezervasyon için %20 kapora alınır, onay sonrası kesinleşir.

Kapsam dışı sorularda nazikçe "Bu konuda yardımcı olamam, saha rezervasyonu veya maç hakkında bir sorun var mı?" de.
Cevaplarını 2-3 cümleyi geçmeyecek şekilde kısa tut.`;

export const geminiChat = onCall(
  {
    secrets: [geminiKey],
    region: "europe-west1",
    cors: true,
  },
  async (request) => {
    const { message, history } = request.data as {
      message: string;
      history: { role: string; text: string }[];
    };

    if (!message || message.trim() === "") {
      throw new HttpsError("invalid-argument", "Mesaj boş olamaz.");
    }

    const genAI = new GoogleGenerativeAI(geminiKey.value());
    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash-preview-04-17",
      systemInstruction: SYSTEM_PROMPT,
    });

    // Önceki mesajları Gemini formatına çevir
    const formattedHistory = (history || []).map((msg) => ({
      role: msg.role === "user" ? "user" : "model",
      parts: [{ text: msg.text }],
    }));

    const chat = model.startChat({ history: formattedHistory });
    const result = await chat.sendMessage(message);
    const reply = result.response.text();

    return { reply };
  }
);
