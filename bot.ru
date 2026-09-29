import asyncio
import logging
import os

# Устанавливаем всё необходимое прямо при старте
os.system("pip install aiogram requests python-dotenv")

from aiogram import Bot, Dispatcher, F, types
from aiogram.filters import CommandStart
import requests

TELEGRAM_TOKEN = "8845426734:AAF5XCuBSQAwtMuF_qepYqQiYV_ke3TWVEE"
GEMINI_API_KEY = "AQ.Ab8RN6IR_Gea2YflKLTPAeZCdfr90_2TCJngXNKVPcHMUT745g"

bot = Bot(token=TELEGRAM_TOKEN)
dp = Dispatcher()


@dp.message(CommandStart())
async def cmd_start(message: types.Message):
  await message.answer("Привет! Бот на связи и готов общаться.")


@dp.message(F.text)
async def handle_message(message: types.Message):
  await bot.send_chat_action(chat_id=message.chat.id, action="typing")
  try:
    # Делаем прямой запрос к API Gemini с твоим токеном
    url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    headers = {
        "Authorization": f"Bearer {GEMINI_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {"contents": [{"parts": [{"text": message.text}]}]}

    response = requests.post(url, headers=headers, json=payload)
    data = response.json()

    # Достаем ответ из JSON-ответа Google
    answer_text = data["candidates"][0]["content"]["parts"][0]["text"]
    await message.answer(answer_text)

  except Exception as e:
    logging.error(f"Ошибка: {e}")
    await message.answer(
        f"Произошла ошибка при обращении к модели. Детали: {str(e)[:100]}"
    )


async def main():
  logging.basicConfig(level=logging.INFO)
  print("Бот запущен...")
  await dp.start_polling(bot)


if __name__ == "__main__":
  asyncio.run(main())
