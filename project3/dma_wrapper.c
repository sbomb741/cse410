//#include <stdint.h>
extern void dma(void);



extern void dma_set_src_dest(const unsigned int dma_channel_ctrl_base,
                             unsigned char channel,
                             unsigned int src_end_ptr,
                             unsigned int dest_end_ptr);

extern void dma_set_channel_ctrl(const unsigned int dma_channel_ctrl_base,
                      unsigned char channel,
                      unsigned char dest_increment,
                      unsigned char src_increment,
                      unsigned char item_size,
                      unsigned char arbitration_size,
                      unsigned short transfer_size);



extern void dma_set_channel_peripheral(unsigned char channel,
                                unsigned char peripheral);
/**
 * main.c
 */
int main(void)
{
    dma();
    return 0;
}




void dma_set_src_dest(const unsigned int dma_channel_ctrl_base,
                             unsigned char channel,
                             unsigned int src_end_ptr,
                             unsigned int dest_end_ptr)
{
    // Figure out where in the dma channel control should be updated.
    unsigned short channel_offset = (channel << 4);
    unsigned int* channel_control = (unsigned int *)(dma_channel_ctrl_base + channel_offset);

    // Store the source & destination end addresses.
    *channel_control = src_end_ptr;
    channel_control += 1;
    *channel_control = dest_end_ptr;

}

void dma_set_channel_ctrl(const unsigned int dma_channel_ctrl_base,
                      unsigned char channel,
                      unsigned char dest_increment,
                      unsigned char src_increment,
                      unsigned char item_size,
                      unsigned char arbitration_size,
                      unsigned short transfer_size)
{

    register unsigned int control = 0;

    control |= (dest_increment << 30);
    control |= (item_size << 28);

    control |= (src_increment << 26);
    control |= (item_size << 24);

    control |= (arbitration_size << 14);

    control |= ((transfer_size - 1) << 4);

    unsigned short channel_offset = (channel << 4);
    unsigned int* channel_control = (unsigned int *)(dma_channel_ctrl_base + channel_offset);

    channel_control += 2; // go to the control word section for this channel.
    *channel_control = control;
}



void dma_set_channel_peripheral(unsigned char channel,
                                unsigned char peripheral)
{
    register unsigned int DMA_BASE = 0x400ff000;
    unsigned short channel_map_offset = 0x510;

    // DMA channel map starts at offset 0x510.
    // each register holds 8 channels to map.
    channel_map_offset += (channel / 8) * 4;
    unsigned char byte_offset = (channel % 8) * 4;
    *((volatile unsigned int*)(DMA_BASE + channel_map_offset)) |= (peripheral << byte_offset);

    // Set primary control structure.
    *((volatile unsigned int*)(DMA_BASE + 0x034)) |= (1 << channel);

    // Allow peripheral to make DMA requests.
    *((volatile unsigned int*)(DMA_BASE + 0x024)) |= (1 << channel);
}
