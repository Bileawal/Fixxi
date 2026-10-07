from googletrans import Translator
import asyncio
async def run():
    t = Translator()
    res1 = await t.translate('Deewar ka switch aur regulator dono ON hain?', dest='en')
    res2 = await t.translate('Deewar ka switch aur regulator dono ON hain?', dest='ur')
    print(res1.text)
    print(res2.text)
asyncio.run(run())
