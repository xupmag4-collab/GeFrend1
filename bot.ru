import asyncio
import json
import logging
import os

os.system("pip install aiogram")

from aiogram import Bot, Dispatcher, F, types
from aiogram.filters import CommandStart

TELEGRAM_TOKEN = "8845426734:AAE175GrROXHhLcvJNPUyCNuNSF0ByENGNc"

bot = Bot(token=TELEGRAM_TOKEN)
dp = Dispatcher()

MEMORY_FILE = "bot_memory.json"


def load_memory():
  if os.path.exists(MEMORY_FILE):
    try:
      with open(MEMORY_FILE, "r", encoding="utf-8") as f:
        return json.load(f)
    except:
      pass
  return {
      "привет": "Привет! Я автономный бот-автоответчик.",
      "как дела": "Идет автономная работа! А у тебя как?",
  }


def save_memory(memory):
  with open(MEMORY_FILE, "w", encoding="utf-8") as f:
    json.dump(memory, f, ensure_ascii=False, indent=4)


bot_memory = load_memory()


@dp.message(CommandStart())
async def cmd_start(message: types.Message):
  await message.answer(
      "Привет! Чтобы научить меня отвечать, используй формат:\n`учи: вопрос |"
      " ответ`",
      parse_mode="Markdown",
  )


@dp.message(F.text)
async def handle_message(message: types.Message):
  text = message.text.strip().lower()

  if text.startswith("учи:"):
    try:
      parts = text[4:].split("|")
      if len(parts) == 2:
        question = parts[0].strip()
        answer = parts[1].strip()
        bot_memory[question] = answer
        save_memory(bot_memory)
        await message.answer(f"✅ Научился отвечать на: «{question}»")
        return
    except Exception:
      pass
    await message.answer(
        "❌ Ошибка формата. Пример:\n`учи: привет | здорово`",
        parse_mode="Markdown",
    )
    return

  response = None
  for key in bot_memory:
    if key in text:
      response = bot_memory[key]
      break

  if response:
    await message.answer(response)
  else:
    await message.answer(f"🤔 Я еще не знаю это. Научи меня:\n`учи: {text} | ответ`", parse_mode="Markdown")


async def main():
  logging.basicConfig(level=logging.INFO)
  print("Запуск автономного бота...")
  await bot.delete_webhook(drop_pending_updates=True)
  await dp.start_polling(bot)


if __name__ == "__main__":
  asyncio.run(main())
