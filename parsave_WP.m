% worm paparazzi save data during the loop 

function parsave_WP(save_name,zstack_aft,zstack_bef,thisROI,first_image,last_image,centroids_aft,centroids_bef)

    java.lang.Thread.sleep(.1*1000);

    save(save_name,'zstack_aft','zstack_bef','thisROI','first_image','last_image','centroids_aft','centroids_bef');

end