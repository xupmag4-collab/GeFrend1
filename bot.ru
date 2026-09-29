import asyncio
import logging
import os

from aiogram import Bot, Dispatcher, F, types
from aiogram.filters import CommandStart
import requests

TELEGRAM_TOKEN = "8845426734:AAE175GrROXHhLcvJNPUyCNuNSF0ByENGNc"
GROQ_API_KEY = "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"

bot = Bot(token=TELEGRAM_TOKEN)
dp = Dispatcher()


@dp.message(CommandStart())
async def cmd_start(message: types.Message):
  await message.answer(
      "Привет! Я твой ИИ-бот на базе Groq, работающий в облаке Hugging Face."
      " Напиши мне что-нибудь!"
  )


@dp.message(F.text)
async def handle_message(message: types.Message):
  await bot.send_chat_action(chat_id=message.chat.id, action="typing")

  try:
    url = "https://api.groq.com/openai/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": "llama3-8b-8192",
        "messages": [
            {
                "role": "system",
                "content": "Ты полезный, дружелюбный и краткий ассистент.",
            },
            {"role": "user", "content": message.text},
        ],
    }

    response = requests.post(url, headers=headers, json=payload)
    data = response.json()

    if "choices" in data and data["choices"]:
      answer_text = data["choices"][0]["message"]["content"]
      await message.answer(answer_text)
    else:
      error_msg = data.get("error", {}).get("message", "Неизвестная ошибка")
      await message.answer(f"⚠️ Ошибка от Groq API: {error_msg}")

  except Exception as e:
    logging.error(f"Ошибка: {e}")
    await message.answer("Произошла ошибка при обращении к нейросети.")


async def main():
  logging.basicConfig(level=logging.INFO)
  print("Запуск Groq Telegram-бота на Hugging Face...")
  await bot.delete_webhook(drop_pending_updates=True)
  await dp.start_polling(bot)


if __name__ == "__main__":
  asyncio.run(main())
