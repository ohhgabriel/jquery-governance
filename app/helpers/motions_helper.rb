module MotionsHelper
  def html_classes_for_motion_list_item(motion, last=false)
    classes = []
    classes << 'acted_on' if member? && current_member.has_acted_on?(motion)
    classes << 'last' if last
    classes.join(' ')
  end

  def render_motion_group(name, motion_group)
    content_tag(:section) do
      content = content_tag(:h2, t("motions.#{name}.heading"))
      if motion_group.empty?
        content << content_tag(:div, t("motions.#{name}.empty"), :class => 'empty')
      else
        content << content_tag(:ul, render_motions_list_items(motion_group), :class => 'motions')
      end
      content.html_safe
    end
  end

  def render_motions_list_items(motions)
    content = ''

    motions.each do |motion|
      content << render(
        :partial => 'motions/list_item',
        :locals  => {
          :motion => motion,
          :last   => motion == motions.last && motions.size >= motions.count
        }
      )
    end

    if link = link_to_more_motions(motions)
      content << content_tag(:li, link.html_safe, :class => 'no-border')
    end

    content.html_safe
  end

  def link_to_more_motions(motions)
    if motions.count > motions.size
      link_to('More', show_more_motions_path, :class => 'more_motions more-button', :'data-last-id' => motions.last.id)
    end
  end

  def motion_status_badge(motion)
    status = if motion.waitingsecond? && motion.expedited?
      'expedited'
    elsif motion.passed?
      'passed'
    elsif motion.approved?
      'approved'
    elsif motion.failed?
      'failed'
    end

    badge(status, :class => "status #{status}") unless status.blank?
  end
end
