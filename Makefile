CC           := gcc
LD           := gcc
SRCS         := main.c cmd.c
OBJS         := main.o cmd.o
TARGET       := dg 

all:
	$(CC) -o $(TARGET) $(SRCS)

clean:
	rm -f $(TARGET) $(OBJS)