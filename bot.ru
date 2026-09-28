import asyncio
import logging
from aiogram import Bot, Dispatcher, F, types
from aiogram.filters import CommandStart
from google import genai

TELEGRAM_TOKEN = "8845426734:AAF5XCuBSQAwtMuF_qepYqQiYV_ke3TWVEE"
GEMINI_API_KEY = "AQ.Ab8RN6IqeLGoiwN96I4rZ4p_wmKqhmTQBUqLWhYNhZ-cAlhmFA"

bot = Bot(token=TELEGRAM_TOKEN)
dp = Dispatcher()
client = genai.Client(api_key=GEMINI_API_KEY)


@dp.message(CommandStart())
async def cmd_start(message: types.Message):
  await message.answer(
      "Привет! Я твой бот на базе Gemini, запущенный на Render."
  )


@dp.message(F.text)
async def handle_message(message: types.Message):
  await bot.send_chat_action(chat_id=message.chat.id, action="typing")
  try:
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=message.text,
    )
    await message.answer(response.text)
  except Exception as e:
    logging.error(f"Ошибка: {e}")
    await message.answer("Произошла ошибка при обращении к модели.")


async def main():
  logging.basicConfig(level=logging.INFO)
  print("Бот запущен в облаке...")
  await dp.start_polling(bot)


if __name__ == "__main__":
  asyncio.run(main())
