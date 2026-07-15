# 1. БАЗА: Откуда берём систему
# Мы берем официальный образ Bazzite с открытыми драйверами NVIDIA.
# Это сохраняет все игровые оптимизации (Steam, Proton, настройки ядра),
# которые есть в оригинальном Bazzite.
FROM ghcr.io/ublue-os/bazzite-nvidia-open:stable

# 2. УДАЛЕНИЕ МУСОРА (Самое важное!)
# rpm-ostree override remove — это магия атомарных систем.
# Она удаляет пакеты из образа так, что они НЕ вернутся при обновлениях.
# Звездочка (*) означает "все пакеты, начинающиеся с..."
RUN rpm-ostree override remove \
    kde-* \                 # Удаляем весь KDE (Plasma, приложения)
    gnome-boxes \           # Удаляем GNOME Boxes
    gnome-software \        # Удаляем магазин приложений GNOME (он тяжелый)
    firefox \               # Удаляем Firefox (если нужен, не удаляй)
    thunderbird \           # Удаляем почту
    libreoffice* \          # Удаляем офисный пакет
    vlc totem epiphany \    # Удаляем медиаплееры и браузер GNOME
    gimp inkscape blender \ # Удаляем тяжелые графические редакторы
    flatpak lutris  bazaar \               # Удаляем поддержку Flatpak (экономит место и ресурсы)
    && rpm-ostree deploy    # Применяем изменения внутри контейнера сборки

# 3. УСТАНОВКА CINNAMON
# Ставим сам рабочий стол и всё необходимое для его работы.
# Nemo — это файловый менеджер Cinnamon.
# LightDM — это экран входа (в Bazzite по умолчанию SDDM от KDE, нам он не нужен).
RUN dnf install -y \
    cinnamon \
    nemo \
    cinnamon-screensaver \
    lightdm \
    lightdm-gtk-greeter \
    network-manager-applet \
    alsa-utils pulseaudio pavucontrol \
    xdg-utils xdg-user-dirs \
    dbus-x11 mutter \
    && dnf autoremove -y \  # Удаляем зависимости, которые стали лишними после установки
    && dnf clean all        # Очищаем кэш пакетного менеджера (экономим место в ISO)

# 4. АКТИВАЦИЯ LIGHTDM
# Включаем LightDM как основной экран входа.
RUN systemctl enable lightdm

# 5. ОПТИМИЗАЦИЯ CINNAMON (Отключаем тормоза)
# Создаем конфиг, который сразу отключает тяжелые анимации.
# В Cinnamon это критично для слабых ПК или ноутбуков.
RUN mkdir -p /etc/dconf/db/local.d && cat > /etc/dconf/db/local.d/00-cinnamon-minimal <<EOF
[org/cinnamon/desktop/effects]
animations=false
[org/cinnamon/desktop/wm/preferences]
enable-animations=false
EOF
# Применяем настройки dconf сразу при сборке
RUN dconf update

# 6. ФИНАЛЬНАЯ УБОРКА
# Удаляем временные файлы и логи, созданные в процессе сборки.
# Это делает ISO-файл меньше.
RUN rm -rf /var/cache/dnf/* /var/tmp/* /tmp/*
