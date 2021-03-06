UI3dComponent getUIVenue() {
  switch (environment) {
  case SATELLITE: return new UISatellite();
  //case MIDWAY: return new UISatellite();
  }
  return null;
}

abstract class UIVenue extends UI3dComponent {

  final static float BOOTH_SIZE_X = 6*FEET;
  final static float BOOTH_SIZE_Y = 40*INCHES;
  final static float BOOTH_SIZE_Z = 36*INCHES;

  final static float LOGO_SIZE = 100*INCHES;
  final PImage LOGO = loadImage("envelop-logo-clear.png");
  final static float SPEAKER_SIZE_X = 21*INCHES;
  final static float SPEAKER_SIZE_Y = 16*INCHES;
  final static float SPEAKER_SIZE_Z = 15*INCHES;
  
  @Override
  public void onDraw(UI ui, PGraphics pg) {
    pg.stroke(#000000);
    pg.fill(#202020);
    drawFloor(ui, pg);
    
    // Logo
    pg.noFill();
    pg.noStroke();
    pg.beginShape();
    pg.texture(LOGO);
    pg.textureMode(NORMAL);
    pg.vertex(-LOGO_SIZE, .1, -LOGO_SIZE, 0, 1);
    pg.vertex(LOGO_SIZE, .1, -LOGO_SIZE, 1, 1);
    pg.vertex(LOGO_SIZE, .1, LOGO_SIZE, 1, 0);
    pg.vertex(-LOGO_SIZE, .1, LOGO_SIZE, 0, 0);
    pg.endShape(CLOSE);
    
    // Speakers
    pg.fill(#000000);
    pg.stroke(#202020);
    for (Ring ring : venue.rings) {
      pg.translate(ring.cx, 0, ring.cz);
      pg.rotateY(-ring.azimuth);
      pg.translate(0, 9*INCHES, 0);
      pg.rotateX(Ring.SPEAKER_ANGLE);
      pg.box(SPEAKER_SIZE_X, SPEAKER_SIZE_Y, SPEAKER_SIZE_Z);
      pg.rotateX(-Ring.SPEAKER_ANGLE);
      pg.translate(0, 6*FEET-9*INCHES, 0);
      pg.box(SPEAKER_SIZE_X, SPEAKER_SIZE_Y, SPEAKER_SIZE_Z);
      pg.translate(0, 11*FEET + 3*INCHES - 6*FEET, 0);
      pg.rotateX(-Ring.SPEAKER_ANGLE);
      pg.box(SPEAKER_SIZE_X, SPEAKER_SIZE_Y, SPEAKER_SIZE_Z);
      pg.rotateX(Ring.SPEAKER_ANGLE);
      pg.rotateY(ring.azimuth);
      pg.translate(-ring.cx, -11*FEET - 3*INCHES, -ring.cz);
    }
  }
  
  protected abstract void drawFloor(UI ui, PGraphics pg);
}

class UISatellite extends UIVenue {
  public void drawFloor(UI ui, PGraphics pg) {
    
    // Desk
    pg.translate(0, BOOTH_SIZE_Y/2, Satellite.INCIRCLE_RADIUS + BOOTH_SIZE_Z/2);
    pg.box(BOOTH_SIZE_X, BOOTH_SIZE_Y, BOOTH_SIZE_Z);
    pg.translate(0, -BOOTH_SIZE_Y/2, -Satellite.INCIRCLE_RADIUS - BOOTH_SIZE_Z/2);
    
    pg.beginShape();
    for (PVector v : Satellite.PLATFORM_POSITIONS) {
      pg.vertex(v.x, 0, v.y);
    }
    pg.endShape(CLOSE);
    pg.beginShape(QUAD_STRIP);
    for (int vi = 0; vi <= Satellite.PLATFORM_POSITIONS.length; ++vi) {
      PVector v = Satellite.PLATFORM_POSITIONS[vi % Satellite.PLATFORM_POSITIONS.length];
      pg.vertex(v.x, 0, v.y);
      pg.vertex(v.x, -8*INCHES, v.y);
    }
    pg.endShape();
  }
}


class UIEnvelopSource extends UICollapsibleSection {
  UIEnvelopSource(UI ui, float w) {
    super(ui, 0, 0, w, 124);
    setTitle("ENVELOP SOURCE");
    new UIEnvelopMeter(ui, envelop.source, 0, 0, getContentWidth(), 60).addToContainer(this);    
    UIAudio.addGainAndRange(this, 64, envelop.source.gain, envelop.source.range);
    UIAudio.addAttackAndRelease(this, 84, envelop.source.attack, envelop.source.release);
  }
}

class UIEnvelopDecode extends UICollapsibleSection {
  UIEnvelopDecode(UI ui, float w) {
    super(ui, 0, 0, w, 124);
    setTitle("ENVELOP DECODE");
    new UIEnvelopMeter(ui, envelop.decode, 0, 0, getContentWidth(), 60).addToContainer(this);
    UIAudio.addGainAndRange(this, 64, envelop.decode.gain, envelop.decode.range);
    UIAudio.addAttackAndRelease(this, 84, envelop.decode.attack, envelop.decode.release);
  }
}

class UIEnvelopMeter extends UI2dContainer {
      
  public UIEnvelopMeter(UI ui, Envelop.Meter meter, float x, float y, float w, float h) {
    super(x, y, w, h);
    setBackgroundColor(ui.theme.getDarkBackgroundColor());
    setBorderColor(ui.theme.getControlBorderColor());
    
    NormalizedParameter[] channels = meter.getChannels();
    float bandWidth = ((width-2) - (channels.length-1)) / channels.length;
    int xp = 1;
    for (int i = 0; i < channels.length; ++i) {
      int nextX = Math.round(1 + (bandWidth+1) * (i+1));
      new UIEnvelopChannel(channels[i], xp, 1, nextX-xp-1, this.height-2).addToContainer(this);
      xp = nextX;
    }
  }
  
  class UIEnvelopChannel extends UI2dComponent implements UIModulationSource {
    
    private final NormalizedParameter channel;
    private float lev = 0;
    
    UIEnvelopChannel(final NormalizedParameter channel, float x, float y, float w, float h) {
      super(x, y, w, h);
      this.channel = channel;
      addLoopTask(new LXLoopTask() {
        public void loop(double deltaMs) {
          float l2 = UIEnvelopChannel.this.height * channel.getNormalizedf();
          if (l2 != lev) {
            lev = l2;
            redraw();
          }
        }
      });
    }
    
    public void onDraw(UI ui, PGraphics pg) {
      if (lev > 0) {
        pg.noStroke();
        pg.fill(ui.theme.getPrimaryColor());
        pg.rect(0, this.height-lev, this.width, lev);
      }
    }
    
    public LXNormalizedParameter getModulationSource() {
      return this.channel;
    }
  }
}

class UISoundObjects extends UI3dComponent {
  final PFont objectLabelFont; 

  UISoundObjects() {
    this.objectLabelFont = loadFont("Arial-Black-24.vlw");
  }
  
  public void onDraw(UI ui, PGraphics pg) {
    for (Envelop.Source.Channel channel : envelop.source.channels) {
      if (channel.active) {
        float tx = channel.tx;
        float ty = channel.ty;
        float tz = channel.tz;
        pg.directionalLight(40, 40, 40, .5, -.4, 1);
        pg.ambientLight(40, 40, 40);
        pg.translate(tx, ty, tz);
        pg.noStroke();
        pg.fill(0xff00ddff);
        pg.sphere(6*INCHES);
        pg.noLights();
        pg.scale(1, -1);
        pg.textAlign(CENTER, CENTER);
        pg.textFont(objectLabelFont);
        pg.textSize(4);
        pg.fill(#00ddff);
        pg.text(Integer.toString(channel.index), 0, -1*INCHES, -6.1*INCHES);
        pg.scale(1, -1);
        pg.translate(-tx, -ty, -tz);
      }
    }    
  }
}
/*class UIEnvelopSource extends UICollapsibleSection {
  UIEnvelopSource(UI ui, float w) {
    super(ui, 0, 0, w, 124);
    setTitle("ENVELOP SOURCE");
    new UIEnvelopMeter(ui, envelop.source, 0, 0, getContentWidth(), 60).addToContainer(this);    
    UIAudio.addGainAndRange(this, 64, envelop.source.gain, envelop.source.range);
    UIAudio.addAttackAndRelease(this, 84, envelop.source.attack, envelop.source.release);
  }
}

class UIEnvelopDecode extends UICollapsibleSection {
  UIEnvelopDecode(UI ui, float w) {
    super(ui, 0, 0, w, 124);
    setTitle("ENVELOP DECODE");
    new UIEnvelopMeter(ui, envelop.decode, 0, 0, getContentWidth(), 60).addToContainer(this);
    UIAudio.addGainAndRange(this, 64, envelop.decode.gain, envelop.decode.range);
    UIAudio.addAttackAndRelease(this, 84, envelop.decode.attack, envelop.decode.release);
  }
}

class UIEnvelopMeter extends UI2dContainer {
      
  public UIEnvelopMeter(UI ui, Envelop.Meter meter, float x, float y, float w, float h) {
    super(x, y, w, h);
    setBackgroundColor(ui.theme.getDarkBackgroundColor());
    setBorderColor(ui.theme.getControlBorderColor());
    
    NormalizedParameter[] channels = meter.getChannels();
    float bandWidth = ((width-2) - (channels.length-1)) / channels.length;
    int xp = 1;
    for (int i = 0; i < channels.length; ++i) {
      int nextX = Math.round(1 + (bandWidth+1) * (i+1));
      new UIEnvelopChannel(channels[i], xp, 1, nextX-xp-1, this.height-2).addToContainer(this);
      xp = nextX;
    }
  }
  
  class UIEnvelopChannel extends UI2dComponent implements UIModulationSource {
    
    private final NormalizedParameter channel;
    private float lev = 0;
    
    UIEnvelopChannel(final NormalizedParameter channel, float x, float y, float w, float h) {
      super(x, y, w, h);
      this.channel = channel;
      addLoopTask(new LXLoopTask() {
        public void loop(double deltaMs) {
          float l2 = UIEnvelopChannel.this.height * channel.getNormalizedf();
          if (l2 != lev) {
            lev = l2;
            redraw();
          }
        }
      });
    }
    
    public void onDraw(UI ui, PGraphics pg) {
      if (lev > 0) {
        pg.noStroke();
        pg.fill(ui.theme.getPrimaryColor());
        pg.rect(0, this.height-lev, this.width, lev);
      }
    }
    
    public LXNormalizedParameter getModulationSource() {
      return this.channel;
    }
  }
}

class UISoundObjects extends UI3dComponent {
  final PFont objectLabelFont;  //<>//

  UISoundObjects() {
   this.objectLabelFont = loadFont("Arial-Black-24.vlw");
  }
  
  public void onDraw(UI ui, PGraphics pg) {
    for (Envelop.Source.Channel channel : envelop.source.channels) { //<>//
      if (channel.active) {
        float tx = channel.tx;
        float ty = channel.ty;
        float tz = channel.tz;
        pg.directionalLight(40, 40, 40, .5, -.4, 1);
        pg.ambientLight(40, 40, 40);
        pg.translate(tx, ty, tz);
        pg.noStroke();
        pg.fill(0xff00ddff);
        pg.sphere(6*INCHES);
        pg.noLights();
        pg.scale(1, -1);
        pg.textAlign(CENTER, CENTER);
        pg.textFont(objectLabelFont);
        pg.textSize(4);
        pg.fill(#00ddff);
        pg.text(Integer.toString(channel.index), 0, -1*INCHES, -6.1*INCHES);
        pg.scale(1, -1);
        pg.translate(-tx, -ty, -tz);
      }
    }    
  }
}*/
