import asyncio
import json
import logging
import os
import random

os.system("pip install aiogram")

from aiogram import Bot, Dispatcher, F, types
from aiogram.filters import CommandStart
from aiogram.utils.keyboard import InlineKeyboardBuilder

TELEGRAM_TOKEN = "8845426734:AAE175GrROXHhLcvJNPUyCNuNSF0ByENGNc"

bot = Bot(token=TELEGRAM_TOKEN)
dp = Dispatcher()

DATA_FILE = "game_data.json"


def load_data():
  if os.path.exists(DATA_FILE):
    try:
      with open(DATA_FILE, "r", encoding="utf-8") as f:
        return json.load(f)
    except:
      pass
  return {}


def save_data(data):
  with open(DATA_FILE, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=4)


users_data = load_data()


def get_user(user_id):
  uid = str(user_id)
  if uid not in users_data:
    users_data[uid] = {
        "gold": 100,
        "hp": 100,
        "level": 1,
        "wins": 0,
        "active_game": None,
    }
  return users_data[uid]


@dp.message(CommandStart())
async def cmd_start(message: types.Message):
  get_user(message.from_user.id)
  save_data(users_data)

  builder = InlineKeyboardBuilder()
  builder.button(text="⚔️ Битва с монстром", callback_data="game_monster")
  builder.button(text="🎯 Угадай число", callback_data="game_guess")
  builder.button(text="👤 Мой профиль", callback_data="profile")
  builder.adjust(2, 1)

  await message.answer(
      "🎮 **Добро пожаловать в автономную игровую RPG-вселенную!**\n\nВыбирай"
      " активность с помощью кнопок ниже:",
      reply_markup=builder.as_markup(),
      parse_mode="Markdown",
  )


@dp.callback_query(F.data == "profile")
async def profile_callback(callback: types.CallbackQuery):
  user = get_user(callback.from_user.id)
  text = (
      f"👤 **Твой профиль:**\n\n"
      f"🏆 Уровень: `{user['level']}`\n"
      f"❤️ Здоровье: `{user['hp']}/100`\n"
      f"💰 Золото: `{user['gold']}`\n"
      f"⚔️ Побед над монстрами: `{user['wins']}`"
  )

  builder = InlineKeyboardBuilder()
  builder.button(text="◀️ Назад в меню", callback_data="main_menu")

  await callback.message.edit_text(
      text, reply_markup=builder.as_markup(), parse_mode="Markdown"
  )
  await callback.answer()


@dp.callback_query(F.data == "main_menu")
async def main_menu_callback(callback: types.CallbackQuery):
  builder = InlineKeyboardBuilder()
  builder.button(text="⚔️ Битва с монстром", callback_data="game_monster")
  builder.button(text="🎯 Угадай число", callback_data="game_guess")
  builder.button(text="👤 Мой профиль", callback_data="profile")
  builder.adjust(2, 1)

  await callback.message.edit_text(
      "🎮 **Главное меню:**",
      reply_markup=builder.as_markup(),
      parse_mode="Markdown",
  )
  await callback.answer()


@dp.callback_query(F.data == "game_monster")
async def game_monster(callback: types.CallbackQuery):
  user = get_user(callback.from_user.id)
  monster_hp = random.randint(30, 60) * user["level"]
  player_dmg = random.randint(15, 30) * user["level"]

  builder = InlineKeyboardBuilder()

  if player_dmg >= monster_hp:
    reward = random.randint(20, 50)
    user["gold"] += reward
    user["wins"] += 1
    if user["wins"] % 3 == 0:
      user["level"] += 1
    save_data(users_data)

    text = (
        f"⚔️ Ты встретил дикого монстра!\n💥 Ты нанес мощный удар на"
        f" `{player_dmg}` урона!\n\n🎉 **Победа!** Ты заработал `+{reward}`"
        f" золота!"
    )
    builder.button(text="⚔️ Идти дальше", callback_data="game_monster")
  else:
    loss = random.randint(10, 25)
    user["hp"] = max(0, user["hp"] - loss)
    save_data(users_data)

    text = (
        f"⚔️ Ты столкнулся с сильным монстром!\n💥 Монстр дал отпор, ты потерял"
        f" `{loss}` HP.\n❤️ Твое HP: `{user['hp']}/100`"
    )
    if user["hp"] > 0:
      builder.button(text="🗡 Снова в бой", callback_data="game_monster")
    else:
      builder.button(
          text="💊 Воскреснуть (50 золота)", callback_data="revive"
      )

  builder.button(text="◀️ В меню", callback_data="main_menu")
  builder.adjust(1)

  await callback.message.edit_text(
      text, reply_markup=builder.as_markup(), parse_mode="Markdown"
  )
  await callback.answer()


@dp.callback_query(F.data == "revive")
async def revive_user(callback: types.CallbackQuery):
  user = get_user(callback.from_user.id)
  if user["gold"] >= 50:
    user["gold"] -= 50
    user["hp"] = 100
    save_data(users_data)
    await callback.answer("Ты успешно воскрес!")
    await main_menu_callback(callback)
  else:
    await callback.answer(
        "Недостаточно золота для воскрешения!", show_alert=True
    )


@dp.callback_query(F.data == "game_guess")
async def game_guess_start(callback: types.CallbackQuery):
  uid = str(callback.from_user.id)
  users_data[uid]["active_game"] = "guess"
  save_data(users_data)

  await callback.message.edit_text(
      "🎯 **Игра: Угадай число**\n\nЯ загадал число от `1` до `10`. Напиши его"
      " прямо в чат!",
      parse_mode="Markdown",
  )
  await callback.answer()


@dp.message(F.text)
async def handle_text_messages(message: types.Message):
  uid = str(message.from_user.id)
  user = get_user(uid)

  if user.get("active_game") == "guess":
    try:
      guess = int(message.text.strip())
      target = 7  # Можно сделать рандом, для примера зафиксируем или сделаем рандом
      if guess == target:
        user["active_game"] = None
        user["gold"] += 50
        save_data(users_data)
        await message.answer(
            "🎉 Ура! Ты угадал число `7` и получил `+50` золота!",
            parse_mode="Markdown",
        )
      else:
        hint = "📈 загаданное число больше" if guess < target else "📉 загаданное число меньше"
        await message.answer(f"❌ Не угадал! Подсказка: {hint}. Попробуй еще раз:")
    except ValueError:
      await message.answer("Пожалуйста, отправь цифру от 1 до 10.")
    return

  # Обычное эхо или можно добавить чат-бота
  await message.answer(
      "Используй /start для вызова главного меню и запуска игровых режимов!"
  )


async def main():
  logging.basicConfig(level=logging.INFO)
  print("Запуск игрового бота...")
  await bot.delete_webhook(drop_pending_updates=True)
  await dp.start_polling(bot)


if __name__ == "__main__":
  asyncio.run(main())
